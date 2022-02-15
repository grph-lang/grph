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
    static let pos = StructType(elementTypes: [GRPHTypes.float, GRPHTypes.float])
    static let boolean = IntType.int1
    static let direction = IntType.int8
    static let stroke = IntType.int8
    static let string = StructType(elementTypes: [IntType.int64, PointerType(pointee: IntType.int8)])
    
    static let existential = StructType(elementTypes: [PointerType(pointee: IntType.int8), LLVM.ArrayType(elementType: PointerType(pointee: IntType.int8), count: 3)])
    
    /// Warning: void is special. When used as a function return type, it is `VoidType` and has no instances possible, just emptyness
    /// When used in other cases, it is a zero-width type, and is represented by an empty struct, as it is here.
    static let void = StructType(elementTypes: [])
    
    static let stringImmortalMask: UInt64 = 1 << 63
    static let stringNilTerminatedMask: UInt64 = 1 << 62
    static let stringSmallStringMask: UInt64 = 1 << 61
}

extension SimpleType: RepresentableGRPHType {
    var typeid: [UInt8]? {
        switch self {
        case .void:         return [0]
        case .boolean:      return [1]
        case .integer:      return [2]
        case .float:        return [3]
        case .rotation:     return [4]
        case .pos:          return [5]
        case .string:       return [6]
        case .color:        return [7]
        case .linear:       return [8]
        case .radial:       return [9]
        case .direction:    return [10]
        case .stroke:       return [11]
        case .font:         return [12]
        case .shape, .Rectangle, .Circle, .Line, .Polygon, .Text, .Path, .Group, .Background:
            return [100] // reference types, they have an isa instead
        case .num, .mixed, .paint, .funcref:
            return nil // not valid existentials
        }
    }
    
    var representationMode: RepresentationMode {
        switch self {
        case .integer, .float, .rotation, .pos, .boolean, .color, .linear, .radial, .direction, .stroke, .void:
            return .pureValue
        case .string, .font:
            return .impureValue
        case .shape, .Rectangle, .Circle, .Line, .Polygon, .Text, .Path, .Group, .Background:
            return .referenceType
        case .num, .mixed, .paint, .funcref:
            return .existential
        }
    }
    
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
        case .mixed, .paint, .num, .funcref:
            return GRPHTypes.existential
        default:
            print("Illegal usage of an irrepresentable type")
            return VoidType()
        }
    }
}
