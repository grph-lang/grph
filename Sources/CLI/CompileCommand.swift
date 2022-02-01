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
    
    @Argument(help: "The input file to read, as an utf8 encoded grph file", completion: .file(extensions: ["grph"]))
    var input: String
    
    @Option(name: [.customLong("emit")], help: "The output type")
    var dest: CompileDestination?
    
    @Option(name: [.short, .long], help: "The output file")
    var output: String?
    
    mutating func validate() throws {
        switch dest {
        case .parse, .wdiu, .check:
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
        if dest == .check {
            return
        }
        
        let irgen = IRGenerator(filename: (input as NSString).lastPathComponent)
        try irgen.build(from: compiler.rootBlock.children)
        
        try irgen.module.verify()
        
        // -Og, way too cool for us
//        let optimizer = PassPipeliner(module: irgen.module)
//        optimizer.addStandardModulePipeline("")
//        optimizer.execute()
        
        switch dest! {
        case .parse, .wdiu, .check:
            preconditionFailure()
        case .ir:
            try irgen.module.print(to: output!)
        case .bc:
            try irgen.module.emitBitCode(to: output!)
        case .assembly, .object:
            try TargetMachine().emitToFile(module: irgen.module, type: dest == .assembly ? .assembly : .object, path: output!)
        case .executable:
            try TargetMachine().emitToFile(module: irgen.module, type: dest == .assembly ? .assembly : .object, path: "\(output!).o")
            print("Cannot yet create executable. Please execute the following:",
                  "clang -o \(output!) \(output!).o -lgrph", separator: "\n")
            throw ExitCode.failure
        }
    }
}
