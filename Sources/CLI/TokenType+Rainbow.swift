//
//  TokenType+Rainbow.swift
//  grph
//
//  Created by Emil Pedersen on 09/09/2021.
//

import Foundation
import GRPHLexer
import Rainbow

extension TokenType {
    var color: KeyPath<String, String>? {
        switch self {
        case .whitespace, .indent, .commentContent, .squareBrackets, .parentheses, .curlyBraces, .line:
            return nil // keep color of parent
        case .comment:
            return \.green
        case .docComment:
            return \.lightGreen
        case .identifier:
            return \.clearColor
        case .variable:
            return \.lightRed
        case .function:
            return \.blue
        case .method:
            return \.lightBlue
        case .label:
            return \.lightRed
        case .type:
            return \.magenta
        case .namespace:
            return \.yellow
        case .keyword, .nullLiteral, .booleanLiteral:
            return \.magenta.bold
        case .enumCase, .numberLiteral, .rotationLiteral, .posLiteral:
            return \.cyan
        case .commandName:
            return \.red.bold
        case .stringLiteral, .fileLiteral:
            return \.red
        case .stringLiteralEscapeSequence:
            return nil
        case .operator, .assignmentCompound, .assignmentOperator, .lambdaHatOperator, .labelPrefixOperator, .methodCallOperator, .dot, .comma, .slashOperator, .varargs:
            return \.blue
        case .unresolved:
            return \.onRed
        }
    }
}
