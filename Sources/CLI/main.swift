//
//  main.swift
//  Graphism CLI
//
//  Created by Emil Pedersen on 06/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import ArgumentParser
#if os(macOS)
import Darwin
#else
import Glibc
#endif
import Foundation
import GRPHLexer
import GRPHGenerator
import GRPHRuntime
import GRPHValues
import DocGen
import Rainbow

struct GraphismCLI: ParsableCommand {
    
    @Flag(name: [.long, .customShort("c")],
          help: "Only compiles the code and checks for compile errors, without running it")
    var onlyCheck: Bool = false
    
    @Flag(help: "Dumps AST and exits. No other compiling phase will be run.")
    var dumpAst: Bool = false
    
    @Flag(name: [.long],
          help: "Dumps WDIU code and exits. Equivalent to '--wdiu -c'")
    var dumpWdiu: Bool = false
    
    @Flag(name: [.long, .customShort("s")],
          help: "Dumps the code with syntax highlighting, for a terminal")
    var highlight: Bool = false
    
    @Flag(help: "Enables WDIU code dump")
    var wdiu = false
    
    @Flag(help: "Enables step-by-step debugging, printing the current line")
    var debug = false
    
    @Flag(inversion: .prefixedNo, help: "Toggles doc comment parsing (related warnings won't be diagnosed)")
    var doc = true
    
    @Option(name: [.long, .customLong("wait")], help: "Step time between instructions, in seconds (0 by default, or infinity when debugging)")
    var step: TimeInterval?
    
    @Argument(help: "The input file to read, as an utf8 encoded grph file")
    var input: String
    
    @Argument(parsing: .unconditionalRemaining, help: "The arguments to pass to the program, if running it")
    var arguments: [String] = []
    
    mutating func validate() throws {
        if dumpWdiu {
            onlyCheck = true
            wdiu = true
        }
        if dumpAst && highlight {
            throw ValidationError("Incompatible options given, cannot highlight and dump AST")
        }
        if (dumpAst || highlight) && wdiu {
            throw ValidationError("Incompatible options given, cannot dump WDIU while dumping the AST")
        }
        if (onlyCheck || dumpAst || highlight) && (debug || step != nil) {
            throw ValidationError("Incompatible options given, cannot have debug options when running is disabled")
        }
        if (onlyCheck || dumpAst || highlight) && !arguments.isEmpty {
            throw ValidationError("Incompatible options given, cannot have arguments passed when running is disabled")
        }
    }
    
    // That way, the compiler will be deallocated when not needed anymore
    func createRuntime() throws -> (GRPHGenerator, GRPHRuntime) {
        let lexer = GRPHLexer()
        let lines = lexer.parseDocument(content: try String(contentsOfFile: input, encoding: .utf8))
        
        for diag in lexer.diagnostics {
            print(diag.representNicely())
        }
        guard !lexer.diagnostics.contains(where: { $0.severity == .error }) else {
            throw ExitCode.failure
        }
        
        if dumpAst {
            print(lines.map { $0.dumpAST() }.joined(separator: "\n"))
            throw ExitCode.success
        }
        
        let compiler = GRPHGenerator(lines: lines)
        if highlight {
            compiler.ignoreErrors = true
        }
        if highlight || doc {
            compiler.resolvedSemanticTokens = []
        }
        let result = compiler.compile()
        
        let semtokens: [SemanticToken]!
        if doc {
            var docgen = DocGenerator(lines: lines, semanticTokens: compiler.resolvedSemanticTokens!)
            docgen.generate()
            semtokens = docgen.semanticTokens
            compiler.diagnostics.append(contentsOf: docgen.diagnostics)
        } else {
            semtokens = compiler.resolvedSemanticTokens
        }
        
        if highlight {
            for line in lines {
                print(line.highlighted(semanticTokens: semtokens.filter({ $0.token.lineNumber == line.lineNumber })))
            }
            throw ExitCode.success
        }
        
        for diag in compiler.diagnostics {
            print(diag.representNicely())
        }
        
        guard result else {
            throw ExitCode.failure
        }
        
        if wdiu {
            compiler.dumpWDIU()
        }
        if onlyCheck {
            throw ExitCode.success
        }
        let runtime = GRPHRuntime(instructions: compiler.instructions, image: GImage(delegate: {}), argv: [input] + arguments)
        runtime.localFunctions = compiler.imports.compactMap { $0 as? Function }.filter { $0.ns.isEqual(to: NameSpaces.none) }
        
        return (compiler, runtime)
    }
    
    func run() throws {
        setbuf(stdout, nil)
        
        let (compiler, runtime) = try createRuntime()
        
        runtime.debugging = debug
        runtime.debugStep = step ?? (debug ? Double.infinity : 0)
        
        let listener = DispatchQueue(label: "bbtce-listener", qos: .background)
        listener.async { listenForBBTCE(compiler: compiler, runtime: runtime) }
        
        guard runtime.run() else {
            throw ExitCode.failure
        }
    }
    
    func listenForBBTCE(compiler: GRPHGenerator, runtime: GRPHRuntime) {
        while let line = readLine() {
            let cmd = line.components(separatedBy: " ")[0]
            switch cmd {
            case "proceed":
                runtime.debugSemaphore.signal()
            case "+debug":
                runtime.debugging = true
                runtime.debugStep = .infinity
            case "-debug":
                runtime.debugging = false
                runtime.debugStep = 0
                runtime.debugSemaphore.signal()
            case "chwait":
                runtime.debugStep = Double(line.dropFirst(7))! / 1000 // Using milliseconds here for consistency with Java Edition
            case "setwait":
                runtime.debugStep = Double(line.dropFirst(8))! // Using seconds here for consistency with command line argument
            case "eval", "expr":
                do {
                    guard let context = runtime.context else {
                        print("[EVAL ERR No context]")
                        break
                    }
                    let lexer = GRPHLexer()
                    var tokens = lexer.parseLine(lineNumber: -1, content: String(line.dropFirst(5)))
                    lexer.tokenDetectLine(line: &tokens)
                    compiler.context = DebuggingCompilingContext(adapting: context, compiler: compiler)
                    let e = try compiler.resolveExpression(tokens: compiler.trimUselessStuff(children: tokens.children), infer: nil)
                    print("[EVAL OUT \(try e.evalIfRunnable(context: context))]")
                } catch let e as GRPHCompileError {
                    print("[EVAL ERR \(e.message)]")
                } catch let e as DiagnosticCompileError {
                    print("[EVAL ERR \(e.notice.message)]")
                } catch let e as GRPHRuntimeError {
                    print("[EVAL ERR \(e.message)]")
                } catch {
                    print("[EVAL ERR Unexpected error]")
                }
            default:
                break
            }
        }
    }
}

GraphismCLI.main()
