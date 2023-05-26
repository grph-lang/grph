//
//  BinaryExpression.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 29/01/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

extension BinaryExpression: RepresentableExpression {
    func build(generator: IRGenerator) throws -> IRValue {
        if op == .logicalAnd || op == .logicalOr {
            return try buildShortCircuiting(generator: generator)
        }
        if op == .equal || op == .notEqual {
            return try buildEquality(generator: generator)
        }
        // TODO: handle num existential everywhere + handle pos
        var handles: [() -> Void] = []
        defer {
            handles.forEach { $0() }
        }
        let left = try self.left.borrowWithHandle(generator: generator, expect: operands, handles: &handles)
        let right = try self.right.borrowWithHandle(generator: generator, expect: operands, handles: &handles)
        switch op {
        case .greaterOrEqualTo, .lessOrEqualTo, .greaterThan, .lessThan:
            if operands == .integer {
                return generator.builder.buildICmp(left, right, op.icmpPredicate)
            }
            return generator.builder.buildFCmp(left, right, op.fcmpPredicate)
        case .bitwiseAnd:
            return generator.builder.buildAnd(left, right)
        case .bitwiseOr:
            return generator.builder.buildOr(left, right)
        case .bitwiseXor:
            return generator.builder.buildXor(left, right)
        case .bitshiftLeft:
            return generator.builder.buildShl(left, right)
        case .bitshiftRight:
            return generator.builder.buildShr(left, right, isArithmetic: true)
        case .bitrotation:
            return generator.builder.buildShr(left, right, isArithmetic: false)
        case .plus:
            let addition = generator.builder.buildAdd(left, right)
            if (operands == .rotation) {
                return generator.builder.buildRem(addition, GRPHTypes.rotation.constant(360))
            }
            return addition
        case .minus:
            let subtraction = generator.builder.buildSub(left, right)
            if (operands == .rotation) {
                let dis = generator.builder.buildAdd(subtraction, GRPHTypes.rotation.constant(360))
                return generator.builder.buildRem(dis, GRPHTypes.rotation.constant(360))
            }
            return subtraction
        case .multiply:
            return generator.builder.buildMul(left, right)
        case .divide:
            return generator.builder.buildDiv(left, right)
        case .modulo:
            return generator.builder.buildRem(left, right)
        case .concat:
            return generator.builder.buildCall(generator.module.getOrInsertFunction(named: "grphop_concat_strings", type: FunctionType([GRPHTypes.string, GRPHTypes.string], GRPHTypes.string)), args: [left, right])
        case .logicalOr, .logicalAnd, .equal, .notEqual:
            preconditionFailure()
        }
    }
    
    func buildShortCircuiting(generator: IRGenerator) throws -> IRValue {
        let left = try self.left.owned(generator: generator, expect: SimpleType.boolean)
        
        let shortBranch = generator.builder.currentFunction!.appendBasicBlock(named: "shortcircuit")
        let longBranch = generator.builder.currentFunction!.appendBasicBlock(named: "longcircuit")
        let mergeBranch = generator.builder.currentFunction!.appendBasicBlock(named: "merge")
        
        generator.builder.buildCondBr(condition: left,
                                      then: op == .logicalOr ? shortBranch : longBranch,
                                      else: op == .logicalOr ? longBranch : shortBranch)
        
        generator.builder.positionAtEnd(of: shortBranch)
        generator.builder.buildBr(mergeBranch)
        
        generator.builder.positionAtEnd(of: longBranch)
        let right = try self.right.owned(generator: generator, expect: SimpleType.boolean)
        let longLastBr = generator.builder.insertBlock!
        generator.builder.buildBr(mergeBranch)
        
        generator.builder.positionAtEnd(of: mergeBranch)
        let result = generator.builder.buildPhi(GRPHTypes.boolean)
        result.addIncoming([
            (left, shortBranch),
            (right, longLastBr)
        ])
        return result
    }
    
    func buildEquality(generator: IRGenerator) throws -> IRValue {
        var handles: [() -> Void] = []
        defer {
            handles.forEach { $0() }
        }
        let left = try self.left.borrowWithHandle(generator: generator, expect: nil, handles: &handles)
        let right = try self.right.borrowWithHandle(generator: generator, expect: nil, handles: &handles)
        if left.type is IntType && right.type is IntType {
            return generator.builder.buildICmp(left, right, op.icmpPredicate)
        } else if left.type is FloatType && right.type is FloatType {
            return generator.builder.buildFCmp(left, right, op.fcmpPredicate)
        } else if self.left.getType() == SimpleType.type && self.right.getType() == SimpleType.type {
            return generator.builder.buildICmp(generator.builder.buildPointerDifference(left, right), 0, op.icmpPredicate)
        } else if self.left is NullExpression {
            return try buildNullCheck(generator: generator, value: right, type: self.right.getType())
        } else if self.right is NullExpression {
            return try buildNullCheck(generator: generator, value: left, type: self.left.getType())
        }
        // TODO: other types
        throw GRPHCompileError(type: .unsupported, message: "Unsupported operator \(op)")
    }
    
    func buildNullCheck(generator: IRGenerator, value: IRValue, type: GRPHType) throws -> IRValue {
        if type is OptionalType {
            let isset = generator.builder.buildExtractValue(value, index: 0)
            if op == .notEqual {
                return isset
            } else if op == .equal {
                return generator.builder.buildNot(isset)
            } else {
                preconditionFailure("Only operations with null allowed are == and !=")
            }
        }
        // TODO: should be allowed for type `mixed`
        throw GRPHCompileError(type: .unsupported, message: "Cannot null check non-optional")
    }
    
    var ownership: Ownership {
        op == .concat ? .owned : .trivial
    }
}

extension BinaryOperator {
    var fcmpPredicate: RealPredicate {
        switch self {
        case .greaterOrEqualTo:
            return .orderedGreaterThanOrEqual
        case .lessOrEqualTo:
            return .orderedLessThanOrEqual
        case .greaterThan:
            return .orderedGreaterThan
        case .lessThan:
            return .orderedLessThan
        case .equal:
            return .orderedEqual
        case .notEqual:
            return .unorderedNotEqual
        default:
            preconditionFailure()
        }
    }
    
    var icmpPredicate: IntPredicate {
        switch self {
        case .greaterOrEqualTo:
            return .signedGreaterThanOrEqual
        case .lessOrEqualTo:
            return .signedLessThanOrEqual
        case .greaterThan:
            return .signedGreaterThan
        case .lessThan:
            return .signedLessThan
        case .equal:
            return .equal
        case .notEqual:
            return .notEqual
        default:
            preconditionFailure()
        }
    }
}
