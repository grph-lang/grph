//
//  DocGenerator.swift
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

public struct DocGenerator {
    
    public var lines: [Token]
    public var semanticTokens: [SemanticToken]
    
    public var diagnostics: [Notice] = []
    public var documentation: [String: Documentation] = [:]
    
    /// If set to true, the generator will issue warnings if a symbol's documentation is incomplete. This will not trigger warnings if a symbol has no documentation at all.
    public var warnOnIncompleteDocumentation: Bool = false
    
    public init(lines: [Token], semanticTokens: [SemanticToken]) {
        self.lines = lines
        self.semanticTokens = semanticTokens
    }
    
    public mutating func generate() {
        for symbol in semanticTokens where symbol.modifiers.contains(.declaration) && symbol.token.tokenType != .parameter {
            generateDocumentation(declaration: symbol)
        }
        // For use of deprecated symbols, add the appropriate Semantic Modifier (for the IDE to strikethrough), and issue a warning
        for (i, token) in semanticTokens.enumerated() {
            if let depr = findDocumentation(index: i)?.deprecation {
                semanticTokens[i].modifiers.insert(.deprecated)
                if !token.modifiers.contains(.declaration) {
                    diagnostics.append(Notice(token: token.token, severity: .warning, source: .docgen, message: "'\(token.token.literal)' is deprecated: \(depr)"))
                }
            }
        }
    }
    
    /// Finds the documentation for the symbol at the given index in `semanticTokens`
    /// - Parameter index: the index of the symbol in the given `semanticTokens` array
    mutating func findDocumentation(index: Int) -> Documentation? {
        let st = semanticTokens[index]
        switch st.token.tokenType {
        case .parameter:
            // always a declaration, same line as the function definition
            if st.modifiers.contains(.documentation) {
                return nil
            }
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
    
    func findDocumentation(sloppyName: String) -> Documentation? {
        return findInternalDocumentation(sloppyName: sloppyName) ?? DocGenerator.builtins.findInternalDocumentation(sloppyName: sloppyName)
    }
    
    private func findInternalDocumentation(sloppyName: String) -> Documentation? {
        return documentation.values.first(where: { $0.symbol.documentationNames.contains(sloppyName) })
    }
    
    /// Searches above the given symbol for doc comments, parses it, and adds it to the documentation.
    /// - Parameter symbol: a semantic token from a declaration, of type 'variable' or 'function'
    mutating func generateDocumentation(declaration symbol: SemanticToken) {
        assert(symbol.modifiers.contains(.declaration), "findDocumentation(declaration:) is supposed to receive symbols for declarations!")
        
        var documentation: [String] = []
        var since: String? = nil
        var deprecation: String? = nil
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
                semanticTokens.append(SemanticToken(token: Token(lineNumber: line.lineNumber, lineOffset: content.startIndex, literal: content.prefix(6), tokenType: .keyword), modifiers: .documentation, data: .none))
                since = String(content.dropFirst(7))
            } else if content.hasPrefix("@deprecated ") {
                semanticTokens.append(SemanticToken(token: Token(lineNumber: line.lineNumber, lineOffset: content.startIndex, literal: content.prefix(11), tokenType: .keyword), modifiers: .documentation, data: .none))
                deprecation = String(content.dropFirst(12))
            } else if content.hasPrefix("@see ") {
                semanticTokens.append(SemanticToken(token: Token(lineNumber: line.lineNumber, lineOffset: content.startIndex, literal: content.prefix(4), tokenType: .keyword), modifiers: .documentation, data: .none))
                see.append(String(content.dropFirst(5)))
            } else if content.hasPrefix("@param ") && !params.isEmpty {
                semanticTokens.append(SemanticToken(token: Token(lineNumber: line.lineNumber, lineOffset: content.startIndex, literal: content.prefix(6), tokenType: .keyword), modifiers: .documentation, data: .none))
                let cnt = content.dropFirst(7).drop(while: { $0.isWhitespace })
                guard let space = cnt.firstIndex(of: " ") else {
                    diagnostics.append(Notice(token: docContent, severity: .warning, source: .docgen, message: "Could not parse doc keyword, expected syntax '@param paramName Your documentation'"))
                    continue
                }
                let name = cnt[..<space]
                semanticTokens.append(SemanticToken(token: Token(lineNumber: line.lineNumber, lineOffset: name.startIndex, literal: name, tokenType: .parameter), modifiers: .documentation, data: .none))
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
        if warnOnIncompleteDocumentation,
           documentation.isEmpty || since == nil || params.contains(where: { $0.doc == nil}) {
            diagnostics.append(Notice(token: symbol.token, severity: .warning, source: .docgen, message: "This symbol's documentation is incomplete"))
        }
        self.documentation[symbol.documentationIdentifier] = Documentation(symbol: symbol, info: documentation.reversed().joined(separator: "\n"), since: since, deprecation: deprecation, seeAlso: see.reversed(), paramDoc: params)
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