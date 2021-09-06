//
//  File.swift
//  File
//
//  Created by Emil Pedersen on 06/09/2021.
//

import Foundation
import GRPHValues
import GRPHLexer

extension BreakInstruction.BreakScope {
    static func parse(tokens: ArraySlice<Token>) throws -> Self {
        switch tokens {
        case TokenMatcher([]):
            return .scopes(1)
        case TokenMatcher(types: .labelPrefixOperator, .label):
            return .label(String(tokens[1].literal))
        case TokenMatcher(types: .numberLiteral):
            if case .integer(let i) = tokens[0].data {
                return .scopes(i)
            }
        default:
            break
        }
        throw DiagnosticCompileError(notice: Notice(token: Token(compound: Array(tokens), type: .squareBrackets), severity: .error, source: .generator, message: "Break instruction expected a label or an integer literal with the amount of scopes"))
    }
}
