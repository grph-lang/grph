//
//  DocGenerator.swift
//  grph
//
//  Created by Emil Pedersen on 10/09/2021.
//

import Foundation
import GRPHLexer
import GRPHGenerator

public struct DocGenerator {
    
    public var lines: [Token]
    public var semanticTokens: [SemanticToken]
    
    public var diagnostics: [Notice] = []
    
    public init(lines: [Token], semanticTokens: [SemanticToken]) {
        self.lines = lines
        self.semanticTokens = semanticTokens
    }
    
    mutating func findDocumentation(declaration symbol: SemanticToken) -> Documentation? {
        assert(symbol.modifiers.contains(.declaration), "findDocumentation(declaration:) is supposed to receive symbols for declarations!")
        
        var documentation: [String] = []
        var since: String? = nil
        var see: [String] = []
        var params = generateParams(declaration: symbol)
        var valid = false
        
        for line in lines[..<symbol.token.lineNumber].reversed() {
            let stripped = line.children.stripped
            guard stripped.count == 1, stripped[0].tokenType == .docComment else {
                break
            }
            valid = true
            let docContent = stripped[0].children[0]
            let content = docContent.literal.drop(while: { $0.isWhitespace })
            if content.hasPrefix("@since ") {
                since = String(content.dropFirst(7))
            } else if content.hasPrefix("@see ") {
                see.append(String(content.dropFirst(5)))
            } else if content.hasPrefix("@param ") && symbol.token.tokenType == .function {
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
            return nil
        }
        return Documentation(symbol: symbol, info: documentation.reversed().joined(separator: "\n"), since: since, seeAlso: see.reversed(), paramDoc: params)
    }
    
    func generateParams(declaration symbol: SemanticToken) -> [Documentation.Parameter] {
        guard symbol.token.tokenType == .function else {
            return []
        }
        return semanticTokens
            .filter { $0.token.lineNumber == symbol.token.lineNumber && $0.token.tokenType == .parameter }
            .map { Documentation.Parameter(name: $0.token.description) }
    }
}
