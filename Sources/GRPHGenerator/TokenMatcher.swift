//
//  TokenMatcher.swift
//  GRPH Generator
//
//  Created by Emil Pedersen on 05/09/2021.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHLexer

struct TokenMatcher: ExpressibleByArrayLiteral {
    var elements: [Component]
    
    init(arrayLiteral elements: Component...) {
        self.elements = elements
    }
    
    init(_ elements: Component...) {
        self.elements = elements
    }
    
    init(_ elements: [Component]) {
        self.elements = elements
    }
    
    init(types: TokenType...) {
        self.elements = types.map { .type($0) }
    }
    
    func matches<T: Collection>(tokens: T) -> Bool where T.Element == Token {
        guard tokens.count == elements.count else {
            return false
        }
        for (token, component) in zip(tokens, elements) {
            switch component {
            case let .one(type: type, literal: literal):
                guard literal == nil || literal! == token.literal,
                      type == nil || type == token.tokenType else {
                    return false
                }
            }
        }
        return true
    }
    
    static func ~= <T: Collection>(lhs: TokenMatcher, rhs: T) -> Bool where T.Element == Token {
        lhs.matches(tokens: rhs)
    }
    
    enum Component: ExpressibleByStringLiteral {
        case one(type: TokenType?, literal: String?)
        
        init(stringLiteral value: StringLiteralType) {
            self = .literal(value)
        }
        
        static func type(_ type: TokenType) -> Self {
            .one(type: type, literal: nil)
        }
        
        static func literal(_ str: String) -> Self {
            .one(type: nil, literal: str)
        }
        
        static var any: Self {
            .one(type: nil, literal: nil)
        }
    }
}

extension Token {
    var validTypeIdentifier: Bool {
        for child in children {
            switch child.tokenType {
            case .whitespace, .identifier, .type, .operator, .curlyBraces:
                continue
            case .indent, .comment, .docComment, .commentContent, .variable, .function, .method, .keyword, .label, .enumCase, .commandName, .booleanLiteral, .nullLiteral, .numberLiteral, .rotationLiteral, .posLiteral, .stringLiteral, .fileLiteral, .stringLiteralEscapeSequence, .assignmentOperator, .assignmentCompound, .lambdaHatOperator, .labelPrefixOperator, .methodCallOperator, .comma, .dot, .slashOperator, .squareBrackets, .parentheses, .line, .unresolved, .varargs, .namespace, .property, .parameter:
                return false
            }
        }
        return true
    }
}
