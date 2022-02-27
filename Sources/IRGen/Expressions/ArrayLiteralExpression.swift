//
//  ArrayLiteralExpression.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 27/02/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

extension ArrayLiteralExpression: RepresentableExpression {
    func build(generator: IRGenerator) throws -> IRValue {
        try wrapped.inArray.buildNewArray(generator: generator, values: values)
    }
}

extension GRPHValues.ArrayType {
    func createArray(generator: IRGenerator, capacity: Int) -> IRValue {
        return generator.builder.buildCall(generator.module.getOrInsertFunction(named: "grpharr_create", type: FunctionType([PointerType.toVoid, GRPHTypes.integer], PointerType.toVoid)), args: [
            getTypeTableGlobalPtr(generator: generator),
            Int64(capacity)
        ])
    }
    
    func buildNewArray(generator: IRGenerator, values: [Expression]) throws -> IRValue {
        // TODO: capacity would be better with closest power of 2
        let arrayRef = createArray(generator: generator, capacity: values.count)
        for value in values {
            let valueptr = try generator.insertAlloca(type: content.findLLVMType())
            generator.builder.buildStore(try value.tryBuilding(generator: generator, expect: content), to: valueptr)
            _ = generator.builder.buildCall(generator.module.getOrInsertFunction(named: "grpharr_append", type: FunctionType([PointerType.toVoid, PointerType.toVoid], VoidType())), args: [arrayRef, generator.builder.buildBitCast(valueptr, type: PointerType(pointee: IntType.int8))])
        }
        return arrayRef
    }
}
