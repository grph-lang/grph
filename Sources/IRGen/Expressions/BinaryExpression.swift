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
        // TODO handle num existential everywhere + handle pos
        let left = try self.left.tryBuilding(generator: generator)
        let right = try self.right.tryBuilding(generator: generator)
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
            return generator.builder.buildAdd(left, right)
        case .minus:
            return generator.builder.buildSub(left, right)
        case .multiply:
            return generator.builder.buildMul(left, right)
        case .divide:
            return generator.builder.buildDiv(left, right)
        case .modulo:
            return generator.builder.buildRem(left, right)
            // TODO
        default:
            throw GRPHCompileError(type: .unsupported, message: "Unsupported operator \(op)")
//        case .equal:
//            <#code#>
//        case .notEqual:
//            <#code#>
//        case .concat:
//            <#code#>
//        case .logicalAnd:
//            <#code#>
//        case .logicalOr:
//            <#code#>
        }
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
            return .signedLessThanOrEqual
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
