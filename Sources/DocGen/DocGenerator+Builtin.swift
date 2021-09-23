//
//  DocGenerator+Builtin.swift
//  GRPH DocGen
//
//  Created by Emil Pedersen on 10/09/2021.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
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
        #if DEBUG
        builtins.warnOnIncompleteDocumentation = true
        #endif
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
            case "property":
                let gen = GRPHGenerator(lines: lines)
                gen.imports = NameSpaces.instances
                guard let type = GRPHTypes.parse(context: TopLevelCompilingContext(compiler: gen), literal: Token(squash: line.children[5..<(line.children.count - 2)], type: .type).description),
                      let prop = (type.staticConstants + type.fields as [Property]).first(where: { $0.name == line.children.last!.literal }) else {
                    data = .none
                    break
                }
                data = .property(prop, in: type)
            case "namespace", "global", "command":
                data = .identifier(id.description)
            default:
                print("No data for \(line.description)")
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
