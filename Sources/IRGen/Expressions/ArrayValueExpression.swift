//
//  ArrayValueExpression.swift
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

extension ArrayValueExpression: RepresentableExpression {
    func build(generator: IRGenerator) throws -> IRValue {
        let arrayRef = try array.tryBuildingWithoutCaringAboutType(generator: generator)
        let valueptr = try generator.insertAlloca(type: getType().findLLVMType())
        // TODO: removing
        _ = try generator.builder.buildCall(generator.module.getOrInsertFunction(named: removing ? "grpharr_remove" : "grpharr_get", type: FunctionType([PointerType.toVoid, GRPHTypes.integer, PointerType.toVoid], VoidType())), args: [
            arrayRef,
            index!.tryBuilding(generator: generator, expect: SimpleType.integer),
            generator.builder.buildBitCast(valueptr, type: PointerType(pointee: IntType.int8))
        ])
        return try generator.builder.buildLoad(valueptr, type: getType().findLLVMType())
    }
}
