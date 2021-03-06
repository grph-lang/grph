//
//  TokenType+Rainbow.swift
//  Graphism CLI
//
//  Created by Emil Pedersen on 09/09/2021.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
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
        case .variable, .parameter, .property:
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
            return \.clearColor
        case .unresolved:
            return \.onRed
        }
    }
}
