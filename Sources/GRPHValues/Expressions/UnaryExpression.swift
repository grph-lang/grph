//
//  UnaryExpression.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 03/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct UnaryExpression: Expression {
    public let exp: Expression
    public let op: UnaryOperator
    
    public init(context: CompilingContext, op: String, exp: Expression) throws {
        self.op = UnaryOperator(rawValue: op)!
        self.exp = exp
        switch self.op {
        case .bitwiseComplement:
            guard try SimpleType.integer.isInstance(context: context, expression: exp) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs an integer")
            }
        case .opposite:
            guard try SimpleType.num.isInstance(context: context, expression: exp) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs a number")
            }
        case .not:
            guard try SimpleType.boolean.isInstance(context: context, expression: exp) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs a boolean")
            }
        }
    }
    
    public func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        switch op {
        case .bitwiseComplement:
            return SimpleType.integer
        case .opposite:
            return try exp.getType(context: context, infer: infer)
        case .not:
            return SimpleType.boolean
        }
    }
    
    public var needsBrackets: Bool { false }
    
    public var string: String { "\(op.rawValue)\(exp.bracketized)" }
}

public extension UnaryExpression {
    var astNodeData: String {
        "application of unary operator '\(op.rawValue)'"
    }
    
    var astChildren: [ASTElement] {
        [
            ASTElement(name: "value", value: [exp])
        ]
    }
}

public enum UnaryOperator: String {
    case bitwiseComplement = "~"
    case opposite = "-"
    case not = "!"
}

public struct UnboxExpression: Expression {
    public let exp: Expression
    
    public init(exp: Expression) {
        self.exp = exp
    }
    
    public func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        guard let type = try exp.getType(context: context, infer: infer.optional) as? OptionalType else {
            throw GRPHCompileError(type: .typeMismatch, message: "Cannot unbox non optional")
        }
        return type.wrapped
    }
    
    public var needsBrackets: Bool { false }
    
    public var string: String { "\(exp.bracketized)!" }
}

public extension UnboxExpression {
    var astNodeData: String {
        "unwrap optional"
    }
    
    var astChildren: [ASTElement] {
        [
            ASTElement(name: "value", value: [exp])
        ]
    }
}
