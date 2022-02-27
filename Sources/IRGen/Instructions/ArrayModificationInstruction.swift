//
//  ArrayModificationInstruction.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 26/02/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

extension ArrayModificationInstruction: RepresentableInstruction {
    func build(generator: IRGenerator) throws {
        guard let array = generator.currentContext?.findVariable(named: name) else {
            throw GRPHCompileError(type: .undeclared, message: "Variable was not found")
        }
        let arrayRef = try array.getContent(generator: generator)
        let valueptr = try value.map { exp -> IRValue in
            let variable = try generator.insertAlloca(type: exp.getType().findLLVMType())
            generator.builder.buildStore(try exp.tryBuilding(generator: generator, expect: exp.getType()), to: variable)
            return generator.builder.buildBitCast(variable, type: PointerType(pointee: IntType.int8))
        }
        switch op {
        case .add:
            if let index = index {
                _ = try generator.builder.buildCall(generator.module.getOrInsertFunction(named: "grpharr_insert", type: FunctionType([PointerType.toVoid, GRPHTypes.integer, PointerType.toVoid], VoidType())), args: [
                    arrayRef,
                    index.tryBuilding(generator: generator, expect: SimpleType.integer),
                    valueptr!
                ])
            } else {
                _ = generator.builder.buildCall(generator.module.getOrInsertFunction(named: "grpharr_append", type: FunctionType([PointerType.toVoid, PointerType.toVoid], VoidType())), args: [
                    arrayRef,
                    valueptr!
                ])
            }
        case .remove:
            throw GRPHCompileError(type: .unsupported, message: "Trailing equal sign remove is not implemented")
        case .set:
            _ = try generator.builder.buildCall(generator.module.getOrInsertFunction(named: "grpharr_set", type: FunctionType([PointerType.toVoid, GRPHTypes.integer, PointerType.toVoid], VoidType())), args: [
                arrayRef,
                index!.tryBuilding(generator: generator, expect: SimpleType.integer),
                valueptr!
            ])
        }
    }
}
