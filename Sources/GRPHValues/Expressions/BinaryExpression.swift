//
//  BinaryExpression.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 02/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct BinaryExpression: Expression {
    public let left, right: Expression
    public var op: BinaryOperator
    public var operands: SimpleType
    public let unbox: Bool
    
    public init(context: CompilingContext, left: Expression, op: String, right: Expression) throws {
        self.left = left
        self.right = right
        self.op = BinaryOperator(string: op)!
        // TYPE CHECKS
        switch self.op {
        case .plus, .concat: // concat impossible here
            if SimpleType.string.isInstance(context: context, expression: left),
               SimpleType.string.isInstance(context: context, expression: right) {
                self.op = .concat
                self.operands = .string
            } else {
                fallthrough
            }
        case .minus:
            if SimpleType.rotation.isInstance(context: context, expression: left),
               SimpleType.rotation.isInstance(context: context, expression: right) {
                self.operands = .rotation
            } else if SimpleType.pos.isInstance(context: context, expression: left),
                      SimpleType.pos.isInstance(context: context, expression: right) {
                       self.operands = .pos
            } else {
                fallthrough
            }
        case .multiply, .divide, .modulo:
            guard SimpleType.num.isInstance(context: context, expression: left),
                  SimpleType.num.isInstance(context: context, expression: right) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs two numbers")
            }
            if SimpleType.integer.isInstance(context: context, expression: left),
               SimpleType.integer.isInstance(context: context, expression: right) {
                operands = .integer
            } else {
                operands = .float
            }
        case .logicalAnd, .logicalOr:
            guard SimpleType.boolean.isInstance(context: context, expression: left),
                  SimpleType.boolean.isInstance(context: context, expression: right) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs two booleans")
            }
            operands = .boolean
        case .greaterThan, .greaterOrEqualTo, .lessThan, .lessOrEqualTo:
            if SimpleType.num.isInstance(context: context, expression: left),
               SimpleType.num.isInstance(context: context, expression: right) {
                if SimpleType.integer.isInstance(context: context, expression: left),
                   SimpleType.integer.isInstance(context: context, expression: right) {
                    operands = .integer
                } else {
                    operands = .float
                }
            } else if SimpleType.pos.isInstance(context: context, expression: left),
                      SimpleType.pos.isInstance(context: context, expression: right) {
                operands = .pos
            } else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs two 'num' or two 'pos'")
            }
        case .bitwiseAnd, .bitwiseOr, .bitwiseXor:
            if SimpleType.integer.isInstance(context: context, expression: left),
               SimpleType.integer.isInstance(context: context, expression: right) {
                operands = .integer
            } else if SimpleType.boolean.isInstance(context: context, expression: left),
                      SimpleType.boolean.isInstance(context: context, expression: right) {
                operands = .boolean
            } else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs two integers or two booleans")
            }
        case .bitshiftLeft, .bitshiftRight, .bitrotation:
            guard SimpleType.integer.isInstance(context: context, expression: left),
                  SimpleType.integer.isInstance(context: context, expression: right) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Operator '\(op)' needs two integers")
            }
            operands = .integer
        case .equal, .notEqual:
            operands = .mixed
            self.unbox = false
            return
        }
        self.unbox = left.getType() is OptionalType ? true : right.getType() is OptionalType
    }
    
    public func getType() -> GRPHType {
        switch op {
        case .logicalAnd, .logicalOr, .greaterThan, .greaterOrEqualTo, .lessThan, .lessOrEqualTo, .equal, .notEqual:
            return SimpleType.boolean
        case .bitshiftLeft, .bitshiftRight, .bitrotation, .bitwiseAnd, .bitwiseOr, .bitwiseXor, .plus, .minus, .multiply, .divide, .modulo, .concat:
            return operands
        }
    }
    
    public var string: String {
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
    
    public var needsBrackets: Bool { true }
}

public extension BinaryExpression {
    var astNodeData: String {
        "application of operator '\(op.string)' between two \(operands)"
    }
    
    var astChildren: [ASTElement] {
        [
            ASTElement(name: "lhs", value: [left]),
            ASTElement(name: "rhs", value: [right]),
        ]
    }
}

public enum BinaryOperator: String {
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
    
    public init?(string: String) {
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
    
    public var string: String {
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
