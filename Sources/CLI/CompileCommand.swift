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
import Foundation
import GRPHLexer
import GRPHGenerator
import GRPHValues
import DocGen
import IRGen
import LLVM

struct CompileCommand: ParsableCommand {
    
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "compile", abstract: "Compile GRPH code, without running it")
    }
    
    @Flag(inversion: .prefixedNo, help: "Toggles doc comment parsing (& related warnings)")
    var doc = true
    
    @Flag(inversion: .prefixedEnableDisable, help: ArgumentHelp("Include top level code as the main function", discussion: "When top level code is disabled, non-constant globals will be left uninitialized, as all top level code will be removed"))
    var topLevelCode = true
    
    @Flag(inversion: .prefixedEnableDisable, help: "Mangle the name of functions. If disabled, functions will be callable from C code by their name")
    var mangling = true
    
    @Argument(help: "The input file to read, as an utf8 encoded grph file", completion: .file(extensions: ["grph"]))
    var input: String
    
    @Option(name: [.customLong("emit")], help: "The output type")
    var dest: CompileDestination?
    
    @Option(name: [.short, .long], help: "The output file")
    var output: String?
    
    mutating func validate() throws {
        switch dest {
        case .parse, .wdiu, .ast, .check:
            if output != nil {
                throw ValidationError("Emition type does not support output file")
            }
        case .ir, .bc, .assembly, .object, .executable:
            if output == nil {
                output = dest!.defaultOutputFile(input: input)
            }
        case nil:
            if let output = output {
                dest = CompileDestination(outputFile: output) ?? .executable
            } else {
                dest = .executable
                output = CompileDestination.executable.defaultOutputFile(input: "")
            }
        }
    }
    
    func run() throws {
        let lexer = GRPHLexer()
        let lines = lexer.parseDocument(content: try String(contentsOfFile: input, encoding: .utf8))
        
        for diag in lexer.diagnostics {
            print(diag.representNicely())
        }
        guard !lexer.diagnostics.contains(where: { $0.severity == .error }) else {
            throw ExitCode.failure
        }
        
        if dest == .parse {
            print(lines.map { $0.dumpAST() }.joined(separator: "\n"))
            return
        }
        
        let compiler = GRPHGenerator(lines: lines)
        if doc {
            compiler.resolvedSemanticTokens = []
        }
        let result = compiler.compile()
        
        if doc {
            var docgen = DocGenerator(lines: lines, semanticTokens: compiler.resolvedSemanticTokens!)
            docgen.generate()
            compiler.diagnostics.append(contentsOf: docgen.diagnostics)
        }
        
        for diag in compiler.diagnostics {
            print(diag.representNicely())
        }
        
        guard result else {
            throw ExitCode.failure
        }
        
        if dest == .wdiu {
            compiler.dumpWDIU()
            return
        }
        if dest == .ast {
            print(compiler.rootBlock.dumpAST())
            return
        }
        if dest == .check {
            return
        }
        
        let irgen = IRGenerator(filename: (input as NSString).lastPathComponent)
        irgen.mangleNames = mangling
        try irgen.build(from: compiler.rootBlock.children)
        
        if !topLevelCode {
            irgen.module.function(named: "main")?.delete()
        }
        
        try irgen.module.verify()
        
        // -O2, way too cool for us
//        let optimizer = PassPipeliner(module: irgen.module)
//        optimizer.addStandardModulePipeline("")
//        optimizer.execute()
        
        switch dest! {
        case .parse, .wdiu, .ast, .check:
            preconditionFailure()
        case .ir:
            try irgen.module.print(to: output!)
        case .bc:
            try irgen.module.emitBitCode(to: output!)
        case .assembly, .object:
            try TargetMachine().emitToFile(module: irgen.module, type: dest == .assembly ? .assembly : .object, path: output!)
        case .executable:
            let tmpfile = URL(fileURLWithPath: "\(output!).\(UUID()).o", relativeTo: FileManager.default.temporaryDirectory)
            try TargetMachine().emitToFile(module: irgen.module, type: .object, path: tmpfile.path)
            let ld = Process()
            // just use clang to link to get all the necessary libraries for the stdlib to work
            // LD works on macOS, but on Linux, it doesn't find _start
            // Find clang in env instead of a specific path
            ld.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            ld.arguments = ["clang", "-o", output!, tmpfile.path, "-lgrph", "-L/usr/local/lib"]
            try ld.run()
            ld.waitUntilExit()
            try? FileManager.default.removeItem(at: tmpfile)
            if ld.terminationStatus != 0 {
                throw ExitCode.failure
            }
        }
    }
}
