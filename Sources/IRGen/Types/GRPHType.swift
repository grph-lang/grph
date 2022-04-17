//
//  GRPHType.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 26/01/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

enum RepresentationMode {
    /// This type is a pure value type (float, color...)
    /// Values of this type are never reference counted
    case pureValue
    /// This type is a value type, but it may contain boxes (string...)
    /// Values of this type must be reference counted recursively
    case impureValue
    /// This type is a reference type (shapes)
    /// Values of this type must be reference counted
    case referenceType
    /// This type is an existential (mixed, num...)
    /// Values of this type must be reference counted recursively
    case existential
}

protocol RepresentableGRPHType: GRPHType {
    /// The typeid representing this raw type
    /// Generics are not included here
    /// Structs have all a value between 0 and 63
    /// Classes have all a value between 64 and 127
    /// Generic types have all a value between 128 and 191
    /// Existential types (can't be instanciated) have a value between 192 and 255
    var typeid: UInt8 { get }
    /// The generics vector to append to the typetable
    var genericsVector: [RepresentableGRPHType] { get }
    /// How the type is represented in memory
    var representationMode: RepresentationMode { get }
    /// Convert to an LLVM type
    func asLLVM() throws -> IRType
}

extension GRPHType {
    func findLLVMType(forReturnType: Bool = false, forParameter: Bool = false) throws -> IRType {
        if forReturnType, self.isTheVoid {
            return VoidType()
        }
        if let ty = self as? RepresentableGRPHType {
            if forParameter, ty.representationMode == .existential {
                return PointerType(pointee: try ty.asLLVM()) // pass existentials in byval pointers
            }
            return try ty.asLLVM()
        } else {
            throw GRPHCompileError(type: .unsupported, message: "Type \(self) not found")
        }
    }
    
    func paramCCWrap(generator: IRGenerator, value: IRValue) -> IRValue {
        guard let self = self as? RepresentableGRPHType else {
            preconditionFailure()
        }
        if self.representationMode == .existential {
            let ptr = generator.insertAlloca(type: GRPHTypes.existential)
            generator.builder.buildStore(value, to: ptr)
            return ptr
        }
        return value
    }
}
