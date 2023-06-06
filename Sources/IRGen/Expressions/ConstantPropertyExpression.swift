//
//  ConstantPropertyExpression.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 12/02/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

extension ConstantPropertyExpression: RepresentableExpression {
    func build(generator: IRGenerator) throws -> IRValue {
        switch (inType, property.name) {
        case (SimpleType.integer, "MIN"):
            return GRPHTypes.integer.constant(Int64.min)
        case (SimpleType.integer, "MAX"):
            return GRPHTypes.integer.constant(Int64.max)
            
        case (SimpleType.float, "POSITIVE_INFINITY"):
            return GRPHTypes.float.constant(Double.infinity)
        case (SimpleType.float, "NEGATIVE_INFINITY"):
            return GRPHTypes.float.constant(-Double.infinity)
        case (SimpleType.float, "NOT_A_NUMBER"):
            return GRPHTypes.float.constant(-Double.nan)
            
        case (SimpleType.pos, "ORIGIN"):
            return GRPHTypes.pos.constant(values: [GRPHTypes.float.constant(0), GRPHTypes.float.constant(0)])
            
        case (SimpleType.void, "VOID"):
            return GRPHTypes.void.constant(values: [])

        case (SimpleType.direction, "RIGHT"):
            return GRPHTypes.direction.constant(0)
        case (SimpleType.direction, "DOWN_RIGHT"):
            return GRPHTypes.direction.constant(1)
        case (SimpleType.direction, "DOWN"):
            return GRPHTypes.direction.constant(2)
        case (SimpleType.direction, "DOWN_LEFT"):
            return GRPHTypes.direction.constant(3)
        case (SimpleType.direction, "LEFT"):
            return GRPHTypes.direction.constant(4)
        case (SimpleType.direction, "UP_LEFT"):
            return GRPHTypes.direction.constant(5)
        case (SimpleType.direction, "UP"):
            return GRPHTypes.direction.constant(6)
        case (SimpleType.direction, "UP_RIGHT"):
            return GRPHTypes.direction.constant(7)

        case (SimpleType.stroke, "ELONGATED"):
            return GRPHTypes.stroke.constant(0)
        case (SimpleType.stroke, "CUT"):
            return GRPHTypes.stroke.constant(1)
        case (SimpleType.stroke, "ROUNDED"):
            return GRPHTypes.stroke.constant(2)
            
        default:
            throw GRPHCompileError(type: .unsupported, message: "Unsupported constant property: \(inType).\(property.name)")
        }
    }
    
    var ownership: Ownership {
        .trivial
    }
}

extension TypeValueExpression: RepresentableExpression {
    func build(generator: IRGenerator) throws -> IRValue {
        let glob = (type as! RepresentableGRPHType).getTypeTableGlobal(generator: generator)
        return generator.builder.buildBitCast(glob, type: PointerType(pointee: IntType.int8))
    }
    
    var ownership: Ownership {
        .trivial
    }
}
