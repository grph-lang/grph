//
//  Token+LSP.swift
//  GRPH LSP
// 
//  Created by Emil Pedersen on 24/09/2021.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHLexer
import GRPHGenerator
import LanguageServerProtocol

extension Token {
    var startPosition: Position {
        Position(line: lineNumber, utf16index: literal.startIndex.utf16Offset(in: literal.base))
    }
    
    var endPosition: Position {
        Position(line: lineNumber, utf16index: literal.endIndex.utf16Offset(in: literal.base))
    }
    
    var positionRange: Range<Position> {
        startPosition..<endPosition
    }
    
    var positionRangeClosed: ClosedRange<Position> {
        startPosition...endPosition
    }
}

extension SemanticToken.Modifiers {
    static let legend = [
        "declaration",
        "definition",
        "readonly",
        "deprecated",
        "modification",
        "documentation",
        "defaultLibrary",
        "call", // extension to the default set
    ]
}

extension Token {
    /// Converts a line of the AST to a flat array of LSP tokens.
    /// - Parameters:
    ///   - semanticTokens: an array of semantic tokens **on the current line**
    ///   - fallback: the fallback token type. should be nil if self is a .line. Only used for recurisively know of the parent type, if the current token has no format.
    /// - Returns: A flat array of  LSP tokens, out of this AST line.
    func flattenedComplete(semanticTokens: [SemanticToken] = [], fallback: LSPSemanticTokenType? = nil) -> [LSPToken] {
        // matches are either exact same, or bigger
        if let match = semanticTokens.last(where: { sem in
            return sem.token.lineOffset <= self.lineOffset && self.literal.endIndex <= sem.token.literal.endIndex
        }), let type = LSPSemanticTokenType(tokenType: match.token.tokenType) {
            return [LSPToken(lineNumber: lineNumber, literal: match.token.literal, type: type, modifiers: match.modifiers)]
        } else if children.isEmpty,
                  case let newChildren = semanticTokens.filter({ sem in
                      return self.lineOffset <= sem.token.lineOffset && sem.token.literal.endIndex <= self.literal.endIndex
                  }),
                  !newChildren.isEmpty {
            var copy = self
            copy.children = newChildren.map { $0.token }
            return copy.flattenedComplete(semanticTokens: semanticTokens, fallback: fallback)
        }
        
        let mytype = LSPSemanticTokenType(tokenType: self.tokenType) ?? fallback
        let mymodifiers: SemanticToken.Modifiers = tokenType == .docComment ? .documentation : []
        
        var result: [LSPToken] = []
        var i = lineOffset
        for child in children {
            if i < child.lineOffset,
               let mytype = mytype {
                result.append(LSPToken(lineNumber: lineNumber, literal: literal[i..<child.lineOffset], type: mytype, modifiers: mymodifiers))
            }
            result += child.flattenedComplete(semanticTokens: semanticTokens, fallback: mytype)
            i = child.literal.endIndex
        }
        if i < literal.endIndex,
           let mytype = mytype {
            result.append(LSPToken(lineNumber: lineNumber, literal: literal[i..<literal.endIndex], type: mytype, modifiers: mymodifiers))
        }
        return result
    }
}
