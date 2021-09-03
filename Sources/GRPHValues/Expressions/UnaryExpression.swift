//
//  UnaryExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation

struct UnaryExpression: Expression {
    let exp: Expression
    let op: UnaryOperator
    
    init(context: CompilingContext, op: String, exp: Expression) throws {
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
    
    func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        switch op {
        case .bitwiseComplement:
            return SimpleType.integer
        case .opposite:
            return try exp.getType(context: context, infer: infer)
        case .not:
            return SimpleType.boolean
        }
    }
    
    var needsBrackets: Bool { false }
    
    var string: String { "\(op.rawValue)\(exp.bracketized)" }
}

enum UnaryOperator: String {
    case bitwiseComplement = "~"
    case opposite = "-"
    case not = "!"
}

struct UnboxExpression: Expression {
    let exp: Expression
    
    func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        guard let type = try exp.getType(context: context, infer: infer.optional) as? OptionalType else {
            throw GRPHCompileError(type: .typeMismatch, message: "Cannot unbox non optional")
        }
        return type.wrapped
    }
    
    var needsBrackets: Bool { false }
    
    var string: String { "\(exp.bracketized)!" }
}
