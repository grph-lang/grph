//
//  TokenType.swift
//  GRPHLexer
//
//  Created by Emil Pedersen on 27/08/2021.
//

import Foundation

public enum TokenType {
    /// Insignificant whitespace, that gets removed at a later stage. This is also used to separate tokens, so the token literal may be empty.
    case whitespace
    /// Indentation at the beginning of a line. Not necessarily whitespace
    case indent
    /// An ignoreable comment (starting with `//`). Supports children of type `commentContent`.
    case comment
    /// A documentation comment (starting with `///`). Supports children of type `commentContent`.
    case docComment
    /// The content of a comment
    case commentContent
    
    /// A word, that hasn't been resolved yet. Matches `[A-Za-z_$][A-Za-z0-9_]*`
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
    /// A namespace
    case namespace
    
    /// true or false
    case booleanLiteral
    /// null
    case nullLiteral
    /// An integer, a float, or a rotation
    case numberLiteral
    /// A rotation
    case rotationLiteral
    /// A position
    case posLiteral
    /// A double-quoted string. Supports children of type `.stringLiteralEscapeSequence`
    case stringLiteral
    /// A single-quoted string
    case fileLiteral
    /// A two-character escape sequence in a string or file literal. The first character is always a backslash.
    case stringLiteralEscapeSequence
    
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
    /// The `.` token
    case dot
    /// The single `/` token
    case slashOperator
    /// The `...` token
    case varargs
    
    /// A bracketized expression. Supports children.
    case squareBrackets
    /// An expression in parentheses. Supports children.
    case parentheses
    /// An expression in curly braces `{}`. Supports children.
    case curlyBraces
    /// The root token for a line. Supports children.
    case line
    
    /// Anything unknown, out of normal, errored
    case unresolved
}
