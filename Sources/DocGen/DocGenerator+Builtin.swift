//
//  DocGenerator+Builtin.swift
//  DocGen
//
//  Created by Emil Pedersen on 10/09/2021.
//

import Foundation
import GRPHLexer
import GRPHGenerator
import GRPHValues

extension DocGenerator {
    
    static let _builtinsSourcePath = String(#filePath.dropLast("DocGenerator+Builtin.swift".count)) + "builtins.grph"
    
    static let builtins: DocGenerator = {
        let lexer = GRPHLexer()
        let lines = lexer.parseDocument(content: try! String(contentsOf: Bundle.module.url(forResource: "builtins", withExtension: "grph")!))
        // no token detection needed
        var builtins = DocGenerator(lines: lines, semanticTokens: [])
        builtins.populateBuiltins()
        return builtins
    }()
    
    private mutating func populateBuiltins() {
        // #builtin type signature
        for line in lines where line.children.count > 3 && line.children[1].literal == "#builtin" {
            let id = Token(squash: line.children[3...], type: .squareBrackets)
            
            let data: SemanticToken.AssociatedData
            switch line.children[3].literal {
            case "function":
                data = NameSpaces.instances.flatMap({ $0.exportedFunctions }).first(where: { $0.documentationIdentifier == id.literal }).map({ .function($0) }) ?? .none
            case "method":
                data = NameSpaces.instances.flatMap({ $0.exportedMethods }).first(where: { $0.documentationIdentifier == id.literal }).map({ .method($0) }) ?? .none
            case "constructor":
                let gen = GRPHGenerator(lines: lines)
                gen.imports = NameSpaces.instances
                data = GRPHTypes.parse(context: TopLevelCompilingContext(compiler: gen), literal: line.children[5].description)?.constructor.map { .constructor($0) } ?? .none
            default:
                data = .identifier(id.description)
            }
            if case .none = data {
                diagnostics.append(Notice(token: id, severity: .error, source: .docgen, message: "Could not find builtin with documentation identifier"))
            }
            let token = SemanticToken(token: id, modifiers: .declaration, data: data)
            generateDocumentation(declaration: token)
        }
    }
}
