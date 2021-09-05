//
//  File.swift
//  File
//
//  Created by Emil Pedersen on 05/09/2021.
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
    
    func matches(tokens: [Token]) -> Bool {
        guard tokens.count == elements.count else {
            return false
        }
        for (token, component) in zip(tokens, elements) {
            switch component {
            case .literal(let literal):
                if literal != token.literal {
                    return false
                }
            case .type(let type):
                if type != token.tokenType {
                    return false
                }
            }
        }
        return true
    }
    
    static func ~= (lhs: TokenMatcher, rhs: [Token]) -> Bool {
        lhs.matches(tokens: rhs)
    }
    
    enum Component: ExpressibleByStringLiteral {
        case type(TokenType)
        case literal(String)
        
        init(stringLiteral value: StringLiteralType) {
            self = .literal(value)
        }
    }
}
