//
//  TokenType.swift
//  GRPHLexer
//
//  Created by Emil Pedersen on 27/08/2021.
//

import Foundation

public enum TokenType {
    /// Insignificant whitespace, that gets removed at a later stage
    case ignoreableWhiteSpace
    /// Indentation at the beginning of a line. Not necessarily whitespace
    case indent
    /// An ignoreable comment (starting with `//`)
    case comment
    /// A documentation comment (starting with `///`)
    case docComment
    
    /// A word, that hasn't been resolved yet
    case identifier
    /// A variable name
    case variable
    /// A function name
    case function
    /// A method name
    case method
    /// A label name
    case label
    /// A type
    case type
    /// A keyword (as(?)(!), is, global, static, final, auto)
    case keyword
    /// A direction or a stroke type
    case enumCase
    /// A #-command name
    case commandName
    
    /// true or false
    case booleanLiteral
    /// null
    case nullLiteral
    /// An integer
    case integerLiteral
    /// A float
    case floatLiteral
    /// A double-quoted string
    case stringLiteral
    /// A single-quoted string
    case fileLiteral
    
    /// A binary or unary operator
    case `operator`
    /// The `=` token
    case assignmentOperator
    /// Compound operators (assignment + binary operation). Has exactly two children (operator & assignment).
    case assignmentCompound
    /// The `^` token
    case lambdaHatOperator
    /// The `::` token
    case labelPrefixOperator
    /// The `:` token
    case methodCallOperator
    /// The `,` token
    case comma
    /// The `>` token when it is used as a namespace separator
    case namespaceSeparator
    /// The `.` token
    case dot
    
    /// A bracketized expression. Supports children.
    case squareBrackets
    /// An expression in parentheses. Supports children.
    case parentheses
    /// An expression in curly braces `{}`. Supports children.
    case curlyBraces
    
    /// Anything unknown, out of normal, errored
    case unresolved
}
