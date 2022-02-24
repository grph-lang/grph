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

struct HighlightCommand: ParsableCommand {
    
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "highlight", abstract: "Semantic highlight a file in the terminal")
    }
    
    @Flag(inversion: .prefixedNo, help: "Toggles doc comment parsing (doc keyword highlight)")
    var doc = true
    
    @Argument(help: "The input file to read, as an utf8 encoded grph file")
    var input: String
    
    func run() throws {
        let lexer = GRPHLexer()
        let lines = lexer.parseDocument(content: try String(contentsOfFile: input, encoding: .utf8))
        
        for diag in lexer.diagnostics {
            print(diag.representNicely(filepath: input))
        }
        guard !lexer.diagnostics.contains(where: { $0.severity == .error }) else {
            throw ExitCode.failure
        }
        
        let compiler = GRPHGenerator(lines: lines)
        compiler.ignoreErrors = true
        compiler.resolvedSemanticTokens = []
        _ = compiler.compile()
        
        let semtokens: [SemanticToken]!
        if doc {
            var docgen = DocGenerator(lines: lines, semanticTokens: compiler.resolvedSemanticTokens!)
            docgen.generate()
            semtokens = docgen.semanticTokens
            compiler.diagnostics.append(contentsOf: docgen.diagnostics)
        } else {
            semtokens = compiler.resolvedSemanticTokens
        }
        for line in lines {
            print(line.highlighted(semanticTokens: semtokens.filter({ $0.token.lineNumber == line.lineNumber })))
        }
    }
}
