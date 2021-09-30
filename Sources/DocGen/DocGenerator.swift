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
    /// If set to true, the generator will issue new semantic tokens for all command name and enum cases tokens.
    public var generateSemanticTokensForDefaults: Bool = false
    
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
            if let depr = findDocumentation(token: token)?.deprecation {
                semanticTokens[i].modifiers.insert(.deprecated)
                if !token.modifiers.contains(.declaration) {
                    diagnostics.append(Notice(token: token.token, severity: .warning, source: .docgen, message: "'\(token.token.literal)' is deprecated: \(depr)"))
                }
            }
        }
        if generateSemanticTokensForDefaults {
            for line in lines {
                generateDefaultTokens(in: line)
            }
        }
    }
    
    mutating func generateDefaultTokens(in token: Token) {
        switch token.tokenType {
        case .commandName:
            semanticTokens.append(SemanticToken(token: token, modifiers: .defaultLibrary, data: .none))
        case .enumCase:
            semanticTokens.append(SemanticToken(token: token, modifiers: .defaultLibrary, data: .none))
        default:
            break
        }
        for child in token.children {
            generateDefaultTokens(in: child)
        }
    }
    
    /// Finds the documentation for the given symbol
    /// - Parameter token: the sematic token, from the `semanticTokens` array
    public func findDocumentation(token st: SemanticToken) -> Documentation? {
        switch st.token.tokenType {
        case .commandName, .namespace, .property, .enumCase, .method:
            return DocGenerator.builtins.findLocalDocumentation(symbol: st)
        case .variable, .function, .type, .parameter:
            return findLocalDocumentation(symbol: st) ?? DocGenerator.builtins.findLocalDocumentation(symbol: st)
        default:
            return nil
        }
    }
    
    func findLocalDocumentation(symbol: SemanticToken) -> Documentation? {
        return symbol.documentationIdentifier.flatMap { documentation[$0] }
    }
    
    public func findDocumentation(sloppyName: String) -> Documentation? {
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
            guard stripped.count == 2,
                  stripped[1].tokenType == .docComment,
                  let docContent = stripped[1].children.first else {
                break
            }
            valid = true
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
                guard let index = params.firstIndex(where: { $0.name == name }) else {
                    diagnostics.append(Notice(token: Token(lineNumber: line.lineNumber, lineOffset: name.startIndex, literal: name, tokenType: .keyword), severity: .warning, source: .docgen, message: "Function has no parameter '\(name)'"))
                    continue
                }
                let pdoc = cnt[cnt.index(after: space)...].trimmingCharacters(in: .whitespaces)
                params[index].doc = pdoc
                
                let tokenData = semanticTokens.first(where: { $0.token.lineNumber == symbol.token.lineNumber && $0.token.literal == name && $0.token.tokenType == .parameter })?.data ?? SemanticToken.AssociatedData.none
                let psem = SemanticToken(token: Token(lineNumber: line.lineNumber, lineOffset: name.startIndex, literal: name, tokenType: .parameter), modifiers: .documentation, data: tokenData)
                semanticTokens.append(psem)
                
                if case .variable(let v) = tokenData {
                    self.documentation[v.documentationIdentifier] = Documentation(symbol: psem, info: pdoc, since: nil, seeAlso: [], paramDoc: [])
                }
            } else {
                documentation.append(content.trimmingCharacters(in: .whitespaces))
            }
        }
        guard valid, let id = symbol.documentationIdentifier else { // empty
            return
        }
        if warnOnIncompleteDocumentation,
           documentation.isEmpty || since == nil || params.contains(where: { $0.doc == nil}) {
            diagnostics.append(Notice(token: symbol.token, severity: .warning, source: .docgen, message: "This symbol's documentation is incomplete"))
        }
        self.documentation[id] = Documentation(symbol: symbol, info: documentation.reversed().joined(separator: "\n"), since: since, deprecation: deprecation, seeAlso: see.reversed(), paramDoc: params)
    }
    
    func generateParams(declaration symbol: SemanticToken) -> [Documentation.Parameter] {
        switch symbol.data {
        case .function(let f as Parametrable), .method(let f as Parametrable), .constructor(let f as Parametrable):
            return f.parameters.map { Documentation.Parameter(name: $0.name) }
        default:
            return []
        }
    }
    
    public func findReferences(of st: SemanticToken) -> [SemanticToken] {
        guard let id = st.documentationIdentifier else {
            return []
        }
        return semanticTokens.filter({ $0.documentationIdentifier == id })
    }
    
    public func findDeclaration(for st: SemanticToken) -> SemanticToken? {
        return findReferences(of: st).first(where: { $0.modifiers.contains(.declaration) })
    }
    
    public func findDocumentation(function: Function) -> Documentation? {
        return documentation[function.documentationIdentifier] ?? DocGenerator.builtins.documentation[function.documentationIdentifier]
    }
    
    public func findDocumentation(method: GRPHValues.Method) -> Documentation? {
        return documentation[method.documentationIdentifier] ?? DocGenerator.builtins.documentation[method.documentationIdentifier]
    }
    
    public func findDocumentation(constructor: Constructor) -> Documentation? {
        return documentation[constructor.documentationIdentifier] ?? DocGenerator.builtins.documentation[constructor.documentationIdentifier]
    }
}
