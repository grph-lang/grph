//
//  Variable.swift
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
import LLVM
import GRPHValues

class Variable {
    
    var name: String
    var ref: VariableReference
    
    init(name: String, ref: VariableReference) {
        self.name = name
        self.ref = ref
    }
    
    func getContent(generator: IRGenerator) throws -> IRValue {
        switch ref {
        case .global(let ptr as IRValue), .stack(let ptr as IRValue, _), .reference(let ptr):
            guard let ty = ptr.type as? PointerType else {
                throw GRPHCompileError(type: .unsupported, message: "Allocated value is not a pointer")
            }
            return generator.builder.buildLoad(ptr, type: ty.pointee)
        case .ownedValue(let val, _), .borrowedValue(let val):
            return val
        }
    }
    
    func getPointer(generator: IRGenerator) throws -> IRValue {
        switch ref {
        case .global(let ptr as IRValue), .stack(let ptr as IRValue, _), .reference(let ptr):
            return ptr
        case .ownedValue(_, _), .borrowedValue(_):
            throw GRPHCompileError(type: .unsupported, message: "Cannot get pointer to a register")
        }
    }
}

enum VariableReference {
    /// A global variable or constant that is allocated statically
    case global(LLVM.Global)
    /// An owned local constant that is stored in a register, or a constant value
    case ownedValue(IRValue, cleanup: (IRGenerator, IRValue) -> Void)
    /// A borrowed parameter that is stored in a register
    case borrowedValue(IRValue)
    /// An owned local variable that was allocated on the stack
    case stack(IRInstruction, cleanup: (IRGenerator, IRValue) -> Void)
    /// A borrowed reference to an array element, inside a ForEachBlock
    case reference(IRValue)
}
