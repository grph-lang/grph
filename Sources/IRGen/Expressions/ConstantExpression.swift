//
//  ConstantExpression.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 26/01/2022.
//  Copyright © 2022 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

extension ConstantExpression: RepresentableExpression {
    func build(generator: IRGenerator) throws -> IRValue {
        switch value {
        case let value as Int:
            return GRPHTypes.integer.constant(value)
        case let value as Float: // the compiler uses floats, IRGen uses doubles, we lose precision on literals
            return GRPHTypes.float.constant(Double(value))
        case let value as Bool:
            return GRPHTypes.boolean.constant(value ? 1 : 0)
        case let value as Pos:
            return GRPHTypes.pos.constant([
                GRPHTypes.float.constant(Double(value.x)),
                GRPHTypes.float.constant(Double(value.y)),
            ])
        case let value as Rotation:
            return GRPHTypes.rotation.constant(Double(value.value))
        case let value as String:
            let global = generator.builder.addGlobalString(name: "", value: value)
            global.isGlobalConstant = true
            return GRPHTypes.string.constant(values: [
                // immortal bit | size
                IntType.int64.constant((1 << 63) | UInt64(value.utf8.count)),
                generator.builder.buildBitCast(global, type: PointerType(pointee: IntType.int8))
            ])
            // TODO stroke, direction
        default:
            throw GRPHCompileError(type: .unsupported, message: "Unknown constant of type \(type(of: value))")
        }
    }
}
