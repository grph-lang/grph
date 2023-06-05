//
//  AssignmentInstruction.swift
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

extension AssignmentInstruction: RepresentableInstruction {
    func build(generator: IRGenerator) throws {
        guard let assigned = assigned as? RepresentableAssignableExpression else {
            throw GRPHCompileError(type: .unsupported, message: "AssignableExpression of type \(type(of: self)) is not supported in IRGen mode")
        }
        try assigned.withPointer(generator: generator) { ptr in
            if virtualized {
                generator.currentContext = VirtualContext(parent: generator.currentContext, ptr: ptr)
            }
            defer {
                if virtualized {
                    generator.currentContext = generator.currentContext?.parent
                }
            }
            let previous = generator.builder.buildLoad(ptr, type: try assigned.getType().findLLVMType())
            generator.builder.buildStore(try value.owned(generator: generator, expect: assigned.getType()), to: ptr)
            assigned.getType().destroy(generator: generator, value: previous)
        }
    }
}

/// In a `exp += 3` expression, the virtual context holds the pointer to `exp` so that the addition can reuse it.
/// Not very useful for variables, but for complex lvalues, it is mandatory.
class VirtualContext: IRContext {
    var ptr: IRValue
    
    init(parent: IRContext?, ptr: IRValue) {
        self.ptr = ptr
        super.init(parent: parent)
    }
}

extension AssignmentInstruction.VirtualExpression: RepresentableExpression {
    func build(generator: IRGenerator) throws -> IRValue {
        guard let ctx = generator.currentContext as? VirtualContext else {
            preconditionFailure("VirtualExpression referenced outside of VirtualContext")
        }
        return generator.builder.buildLoad(ctx.ptr, type: try type.findLLVMType())
    }
    
    var ownership: Ownership {
        .borrowed
    }
}
