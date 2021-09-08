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
    public var children: [Token] = []
    
    public var data: AssociatedData = .none
    
    public init(lineNumber: Int, lineOffset: String.Index, literal: Substring, tokenType: TokenType) {
        self.lineNumber = lineNumber
        self.lineOffset = lineOffset
        self.literal = literal
        self.tokenType = tokenType
        self.children = []
        self.data = .none
    }
}

extension Token {
    public func represent(indent: String = "") -> String {
        let head = "\(indent)\(literal.debugDescription) \(tokenType) (\(lineNumber):\(lineOffset.utf16Offset(in: literal.base))) \(data)\n"
        
        return head + children.map { $0.represent(indent: indent + "    ") }.joined()
    }
    
    /// Removes absolutely all whitespaces in the token. Should only be used for cleaning debug data, as whitespaces are necessary for splitting arguments.
    internal mutating func stripWhitespaces() {
        children = children.filter { $0.tokenType != .whitespace }.map {
            var copy = $0
            copy.stripWhitespaces()
            return copy
        }
    }
    
    public init(compound tokens: [Token], type: TokenType) {
        self.init(squash: tokens[...], type: type)
        children = tokens
    }
    
    public init(squash tokens: ArraySlice<Token>, type: TokenType) {
        let literal = tokens.first!.literal.base[(tokens.first!.lineOffset)..<(tokens.last!.literal.endIndex)]
        self.init(lineNumber: tokens.first!.lineNumber, lineOffset: literal.startIndex, literal: literal, tokenType: type)
    }
    
    public var description: String {
        String(literal)
    }
}

extension Collection where Element == Token {
    /// Removes all `ignoreableWhiteSpace` directly in the array
    public var stripped: [Token] {
        filter { $0.tokenType != .whitespace }
    }
    
    public func split(on separator: TokenType) -> [[Token]] {
        split(omittingEmptySubsequences: true, whereSeparator: { $0.tokenType == separator }).map { Array($0) }
    }
}

extension Token {
    public enum AssociatedData: Equatable {
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
