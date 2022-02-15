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
    /// The typeid representing this type
    /// Only makes sense for value types
    var typeid: [UInt8]? { get }
    /// How the type is represented in memory
    var representationMode: RepresentationMode { get }
    /// Convert to an LLVM type
    func asLLVM() -> IRType
}

extension GRPHType {
    func findLLVMType(forReturnType: Bool = false) throws -> IRType {
        if forReturnType, self.isTheVoid {
            return VoidType()
        }
        if let ty = self as? RepresentableGRPHType {
            return ty.asLLVM()
        } else {
            throw GRPHCompileError(type: .unsupported, message: "Type \(self) not found")
        }
    }
}
