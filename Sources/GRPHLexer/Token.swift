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
    public var literal: String
    
    /// The type of this token
    public var tokenType: TokenType
    
    /// The children of this token. Not all token types support children
    public var children: [Token]
}
