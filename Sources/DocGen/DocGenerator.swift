//
//  DocGenerator.swift
//  grph
//
//  Created by Emil Pedersen on 10/09/2021.
//

import Foundation
import GRPHLexer
import GRPHGenerator
import GRPHValues

public struct DocGenerator {
    
    public var lines: [Token]
    public var semanticTokens: [SemanticToken]
    
    public var diagnostics: [Notice] = []
    public var documentation: [String: Documentation] = [:]
    
    public init(lines: [Token], semanticTokens: [SemanticToken]) {
        self.lines = lines
        self.semanticTokens = semanticTokens
    }
    
    public mutating func generate() {
        for symbol in semanticTokens where symbol.modifiers.contains(.declaration) {
            generateDocumentation(declaration: symbol)
        }
    }
    
    /// Finds the documentation for the symbol at the given index in `semanticTokens`
    /// - Parameter index: the index of the symbol in the given `semanticTokens` array
    mutating func findDocumentation(index: Int) -> Documentation? {
        let st = semanticTokens[index]
        switch st.token.tokenType {
        case .parameter:
            // always a declaration, same line as the function definition
            guard let f = semanticTokens.firstIndex(where: { $0.token.lineNumber == st.token.lineNumber && $0.token.tokenType == .function }) else {
                assertionFailure("parameters must be on the same line as functions")
                return nil
            }
            return findDocumentation(index: f)?.paramDoc.first(where: { $0.name == st.token.literal })?.doc.map({ Documentation(symbol: st, info: $0, since: nil, seeAlso: [], paramDoc: []) })
        case .commandName, .namespace, .property, .enumCase, .method:
            return DocGenerator.builtins.findDocumentation(symbol: st)
        case .variable, .function, .type:
            return findDocumentation(symbol: st) ?? DocGenerator.builtins.findDocumentation(symbol: st)
        default:
            return nil
        }
    }
    
    func findDocumentation(symbol: SemanticToken) -> Documentation? {
        return documentation[symbol.documentationIdentifier]
    }
    
    /// Searches above the given symbol for doc comments, parses it, and adds it to the documentation.
    /// - Parameter symbol: a semantic token from a declaration, of type 'variable' or 'function'
    mutating func generateDocumentation(declaration symbol: SemanticToken) {
        assert(symbol.modifiers.contains(.declaration), "findDocumentation(declaration:) is supposed to receive symbols for declarations!")
        
        var documentation: [String] = []
        var since: String? = nil
        var see: [String] = []
        var params = generateParams(declaration: symbol)
        var valid = false
        
        for line in lines[..<symbol.token.lineNumber].reversed() {
            let stripped = line.children.stripped
            guard stripped.count == 2, stripped[1].tokenType == .docComment else {
                break
            }
            valid = true
            let docContent = stripped[1].children[0]
            let content = docContent.literal.drop(while: { $0.isWhitespace })
            if content.hasPrefix("@since ") {
                since = String(content.dropFirst(7))
            } else if content.hasPrefix("@see ") {
                see.append(String(content.dropFirst(5)))
            } else if content.hasPrefix("@param ") && !params.isEmpty {
                let cnt = content.dropFirst(7).drop(while: { $0.isWhitespace })
                guard let space = cnt.firstIndex(of: " ") else {
                    diagnostics.append(Notice(token: docContent, severity: .warning, source: .docgen, message: "Could not parse doc keyword, expected syntax '@param paramName Your documentation'"))
                    continue
                }
                let name = cnt[..<space]
                guard let index = params.firstIndex(where: { $0.name == name }) else {
                    diagnostics.append(Notice(token: Token(lineNumber: line.lineNumber, lineOffset: name.startIndex, literal: name, tokenType: .keyword), severity: .warning, source: .docgen, message: "Function has no parameter '\(name)'"))
                    continue
                }
                params[index].doc = cnt[cnt.index(after: space)...].trimmingCharacters(in: .whitespaces)
            } else {
                documentation.append(content.trimmingCharacters(in: .whitespaces))
            }
        }
        guard valid else { // empty
            return
        }
        self.documentation[symbol.documentationIdentifier] = Documentation(symbol: symbol, info: documentation.reversed().joined(separator: "\n"), since: since, seeAlso: see.reversed(), paramDoc: params)
    }
    
    func generateParams(declaration symbol: SemanticToken) -> [Documentation.Parameter] {
        switch symbol.data {
        case .function(let f as Parametrable), .method(let f as Parametrable), .constructor(let f as Parametrable):
            return f.parameters.map { Documentation.Parameter(name: $0.name) }
        default:
            return []
        }
    }
}
