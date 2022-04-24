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
        let valueptr = try generator.insertAlloca(type: getType().findLLVMType())
        try array.borrow(generator: generator, expect: nil) { arrayRef in
            _ = try generator.builder.buildCall(generator.module.getOrInsertFunction(named: removing ? "grpharr_remove" : generator.buildingAThunk ? "grpharr_get_mixed" : "grpharr_get", type: FunctionType([PointerType.toVoid, GRPHTypes.integer, PointerType.toVoid], VoidType())), args: [
                arrayRef,
                index!.owned(generator: generator, expect: SimpleType.integer),
                generator.builder.buildBitCast(valueptr, type: PointerType(pointee: IntType.int8))
            ])
        }
        return try generator.builder.buildLoad(valueptr, type: getType().findLLVMType())
    }
    
    var ownership: Ownership {
        .owned
    }
}
