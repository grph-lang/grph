//
//  SimpleType.swift
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

extension GRPHTypes {
    static let integer = IntType.int64
    static let float = FloatType.double
    static let rotation = FloatType.float
    static let pos = VectorType(elementType: FloatType.double, count: 2)
    static let boolean = IntType.int1
    static let direction = IntType.int8
    static let stroke = IntType.int8
    static let string = StructType(elementTypes: [IntType.int64, PointerType(pointee: IntType.int8)])
    
    /// Warning: void is special. When used as a function return type, it is `VoidType` and has no instances possible, just emptyness
    /// When used in other cases, it is a zero-width type, and is represented by an empty struct, as it is here.
    static let void = StructType(elementTypes: [])
    
    static let stringImmortalMask: UInt64 = 1 << 63
    static let stringNilTerminatedMask: UInt64 = 1 << 62
    static let stringSmallStringMask: UInt64 = 1 << 61
}

extension SimpleType {
    func asLLVM() -> IRType {
        switch self {
        case .integer:
            return GRPHTypes.integer
        case .float:
            return GRPHTypes.float
        case .rotation:
            return GRPHTypes.rotation
        case .pos:
            return GRPHTypes.pos
        case .boolean:
            return GRPHTypes.boolean
        case .direction:
            return GRPHTypes.direction
        case .stroke:
            return GRPHTypes.stroke
        case .string:
            return GRPHTypes.string
        case .void:
            return GRPHTypes.void
        default:
            print("Illegal usage of an irrepresentable type")
            return VoidType()
        }
    }
}
