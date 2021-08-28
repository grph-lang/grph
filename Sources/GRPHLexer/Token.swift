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
    
    public var data: AssociatedData = .none
}

extension Token {
    func represent(indent: String = "") -> String {
        let head = "\(indent)\(literal.debugDescription) \(tokenType) (\(lineNumber):\(lineOffset.utf16Offset(in: literal.base))) \(data)\n"
        
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

extension Token {
    public enum AssociatedData {
        case integer(Int)
        case float(Float)
        case string(String)
        
        case none
    }
}

extension Token.AssociatedData: CustomStringConvertible {
    public var description: String {
        switch self {
        case .integer(let data):
            return data.description
        case .float(let data):
            return data.description
        case .string(let data):
            return data.debugDescription
        case .none:
            return ""
        }
    }
}
