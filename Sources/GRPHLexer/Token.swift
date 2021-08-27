//
//  Token.swift
//  GRPHLexer
//
//  Created by Emil Pedersen on 27/08/2021.
//

import Foundation

public struct Token {
    /// A 0-indexed line number for this token
    public var lineNumber: Int
    
    /// The start offset of this token within the line
    public var lineOffset: String.Index
    
    /// The literal string
    public var literal: Substring
    
    /// The type of this token
    public var tokenType: TokenType
    
    /// The children of this token. Not all token types support children
    public var children: [Token]
}

extension Token {
    func represent(indent: String = "") -> String {
        let head = "\(indent)\(literal.debugDescription) \(tokenType) (\(lineNumber):\(lineOffset.utf16Offset(in: literal.base)))\n"
        
        return head + children.map { $0.represent(indent: indent + "    ") }.joined()
    }
    
    mutating func stripWhitespaces() {
        children = children.filter { $0.tokenType != .ignoreableWhiteSpace }.map {
            var copy = $0
            copy.stripWhitespaces()
            return copy
        }
    }
}
