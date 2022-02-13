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
            return GRPHTypes.pos.constant(values: [
                GRPHTypes.float.constant(Double(value.x)),
                GRPHTypes.float.constant(Double(value.y)),
            ])
        case let value as Rotation:
            return GRPHTypes.rotation.constant(Double(value.value))
        case let value as String:
            let len = value.utf8.count
            let ptrtype = generator.module.dataLayout.intPointerType()
            let ptrsize = ptrtype.width / 8
            if len <= ptrsize {
                // small string
                let bytes = Array(value.utf8)
                var result: UInt64 = 0
                for (i, byte) in bytes.enumerated() {
                    result |= UInt64(byte) << (UInt64(ptrsize - i - 1) * 8 as UInt64)
                }
                if generator.module.dataLayout.byteOrder == .littleEndian {
                    result = result.byteSwapped
                }
                return GRPHTypes.string.constant(values: [
                    IntType.int64.constant(GRPHTypes.stringImmortalMask | (len < ptrsize ? GRPHTypes.stringNilTerminatedMask : 0) | GRPHTypes.stringSmallStringMask | UInt64(len)),
                    generator.builder.buildIntToPtr(ptrtype.constant(result), type: PointerType(pointee: IntType.int8))
                ])
            }
            // long string
            let global = generator.builder.addGlobalString(name: "", value: value)
            global.isGlobalConstant = true
            return GRPHTypes.string.constant(values: [
                IntType.int64.constant(GRPHTypes.stringImmortalMask | GRPHTypes.stringNilTerminatedMask | UInt64(len)),
                generator.builder.buildBitCast(global, type: PointerType(pointee: IntType.int8))
            ])
            // TODO stroke, direction
        default:
            throw GRPHCompileError(type: .unsupported, message: "Unknown constant of type \(type(of: value))")
        }
    }
}
