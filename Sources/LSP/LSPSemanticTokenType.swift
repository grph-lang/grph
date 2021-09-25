//
//  LSPSemanticTokenType.swift
//  GRPH LSP
// 
//  Created by Emil Pedersen on 25/09/2021.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHLexer

enum LSPSemanticTokenType: UInt32, CaseIterable {
    /// A simple or documentation comment
    case comment
    
    /// A variable name
    case variable
    /// A function name
    case function
    /// A method name
    case method
    /// A label name
    case label // extension to the standard LSP tokens
    /// A type
    case type
    /// A direction or a stroke type
    case enumMember
    /// A #-command name
    case command // extension to the standard LSP tokens
    /// A namespace
    case namespace
    /// A parameter name in a function definition
    case parameter
    /// A property of a type
    case property
    
    /// A keyword (as(?)(!), is, global, static, final, auto), or a bool/null literal
    case keyword
    /// An integer, a float, a rotation, or a position
    case number
    /// A double-quoted string or single-quoted file
    case string
    
    /// Any operator
    case `operator`
    
    var name: String {
        String(describing: self)
    }
    
    var index: UInt32 {
        rawValue
    }
}

extension LSPSemanticTokenType {
    init?(tokenType: TokenType) {
        switch tokenType {
        case .comment, .docComment:
            self = .comment
        case .variable:
            self = .variable
        case .function:
            self = .function
        case .method:
            self = .method
        case .label:
            self = .label
        case .type:
            self = .type
        case .enumCase:
            self = .enumMember
        case .commandName:
            self = .command
        case .namespace:
            self = .namespace
        case .parameter:
            self = .parameter
        case .property:
            self = .property
        case .keyword, .booleanLiteral, .nullLiteral:
            self = .keyword
        case .rotationLiteral, .posLiteral, .numberLiteral:
            self = .number
        case .stringLiteral, .fileLiteral:
            self = .string
        case .operator, .assignmentOperator, .assignmentCompound, .lambdaHatOperator, .labelPrefixOperator, .methodCallOperator, .dot, .slashOperator, .varargs:
            self = .operator
        case .whitespace, .indent, .commentContent, .identifier, .stringLiteralEscapeSequence, .comma, .squareBrackets, .parentheses, .curlyBraces, .line, .unresolved:
            return nil
        }
    }
}
