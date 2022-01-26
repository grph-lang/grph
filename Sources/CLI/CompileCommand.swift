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

struct CompileCommand: ParsableCommand {
    
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "compile", abstract: "Compile GRPH code, without running it")
    }
    
    @Flag(inversion: .prefixedNo, help: "Toggles doc comment parsing (& related warnings)")
    var doc = true
    
    @Argument(help: "The input file to read, as an utf8 encoded grph file", completion: .file(extensions: ["grph"]))
    var input: String
    
    @Option(name: [.customLong("emit")])
    var dest: CompileDestination = .check
    
    mutating func validate() throws {
        
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
        
        if dest == .ast {
            print(lines.map { $0.dumpAST() }.joined(separator: "\n"))
            throw ExitCode.success
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
        }
    }
}
