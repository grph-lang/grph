//
//  BinaryExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

struct BinaryExpression: Expression {
    let left, right: Expression
    var op: BinaryOperator
    var operands: SimpleType
    let unbox: Bool
    
    init(context: CompilingContext, left: Expression, op: String, right: Expression) throws {
        self.left = left
        self.right = right
        self.op = BinaryOperator(string: op)!
        // TYPE CHECKS
        switch self.op {
        case .plus, .concat: // concat impossible here
            if try SimpleType.string.isInstance(context: context, expression: left),
               try SimpleType.string.isInstance(context: context, expression: right) {
                self.op = .concat
                self.operands = .string
            } else {
                fallthrough
            }
        case .minus:
            if try SimpleType.rotation.isInstance(context: context, expression: left),
               try SimpleType.rotation.isInstance(context: context, expression: right) {
                self.operands = .rotation
            } else if try SimpleType.pos.isInstance(context: context, expression: left),
                      try SimpleType.pos.isInstance(context: context, expression: right) {
                       self.operands = .pos
            } else {
                fallthrough
            }
        case .multiply, .divide, .modulo:
            guard try SimpleType.num.isInstance(context: context, expression: left),
                  try SimpleType.num.isInstance(context: context, expression: right) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs two numbers")
            }
            if try SimpleType.integer.isInstance(context: context, expression: left),
               try SimpleType.integer.isInstance(context: context, expression: right) {
                operands = .integer
            } else {
                operands = .float
            }
        case .logicalAnd, .logicalOr:
            guard try SimpleType.boolean.isInstance(context: context, expression: left),
                  try SimpleType.boolean.isInstance(context: context, expression: right) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs two booleans")
            }
            operands = .boolean
        case .greaterThan, .greaterOrEqualTo, .lessThan, .lessOrEqualTo:
            if try SimpleType.num.isInstance(context: context, expression: left),
               try SimpleType.num.isInstance(context: context, expression: right) {
                if try SimpleType.integer.isInstance(context: context, expression: left),
                   try SimpleType.integer.isInstance(context: context, expression: right) {
                    operands = .integer
                } else {
                    operands = .float
                }
            } else if try SimpleType.pos.isInstance(context: context, expression: left),
                      try SimpleType.pos.isInstance(context: context, expression: right) {
                operands = .pos
            } else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs two 'num' or two 'pos'")
            }
        case .bitwiseAnd, .bitwiseOr, .bitwiseXor:
            if try SimpleType.integer.isInstance(context: context, expression: left),
               try SimpleType.integer.isInstance(context: context, expression: right) {
                operands = .integer
            } else if try SimpleType.boolean.isInstance(context: context, expression: left),
                      try SimpleType.boolean.isInstance(context: context, expression: right) {
                operands = .boolean
            } else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs two integers or two booleans")
            }
        case .bitshiftLeft, .bitshiftRight, .bitrotation:
            guard try SimpleType.integer.isInstance(context: context, expression: left),
                  try SimpleType.integer.isInstance(context: context, expression: right) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs two integers")
            }
            operands = .integer
        case .equal, .notEqual:
            operands = .mixed
            self.unbox = false
            return
        }
        self.unbox = try left.getType(context: context, infer: operands) is OptionalType ? true : right.getType(context: context, infer: operands) is OptionalType
    }
    
    func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        switch op {
        case .logicalAnd, .logicalOr, .greaterThan, .greaterOrEqualTo, .lessThan, .lessOrEqualTo, .equal, .notEqual:
            return SimpleType.boolean
        case .bitshiftLeft, .bitshiftRight, .bitrotation, .bitwiseAnd, .bitwiseOr, .bitwiseXor, .plus, .minus, .multiply, .divide, .modulo, .concat:
            return operands
        }
    }
    
    var string: String {
        "\(leftString) \(op.string) \(right.bracketized)"
    }
    
    private var leftString: String {
        if !op.multipleNeedsBrackets,
           let left = left as? BinaryExpression,
           left.op == self.op {
            return left.string
        }
        return left.bracketized
    }
    
    var needsBrackets: Bool { true }
}

enum BinaryOperator: String {
    case logicalAnd = "&&"
    case logicalOr = "||"
    case greaterOrEqualTo = "≥"
    case lessOrEqualTo = "≤"
    case greaterThan = ">"
    case lessThan = "<"
    case bitwiseAnd = "&"
    case bitwiseOr = "|"
    case bitwiseXor = "^"
    case bitshiftLeft = "<<"
    case bitshiftRight = ">>"
    case bitrotation = ">>>"
    case equal = "=="
    case notEqual = "!="
    case plus = "+"
    case minus = "-"
    case multiply = "*"
    case divide = "/"
    case modulo = "%"
    case concat = "<+>" // Sign not actually used
    
    init?(string: String) {
        if string == ">=" {
            self = .greaterOrEqualTo
        } else if string == "<=" {
            self = .lessOrEqualTo
        } else if string == "≠" {
            self = .notEqual
        } else {
            self.init(rawValue: string)
        }
    }
    
    var string: String {
        switch self {
        case .concat:
            return "+"
        default:
            return rawValue
        }
    }
    
    var multipleNeedsBrackets: Bool {
        switch self {
        case .logicalOr, .logicalAnd, .bitwiseAnd, .bitwiseOr, .bitwiseXor, .plus, .multiply, .concat:
            return false
        default: return true
        }
    }
}
