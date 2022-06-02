//
//  FunctionReferenceExpression.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 02/06/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

extension FunctionReferenceExpression: RepresentableExpression {
    func build(generator: IRGenerator) throws -> IRValue {
        let fn = try generator.builder.module.getOrInsertFunction(named: function.getMangledName(generator: generator), type: FunctionType(function.llvmParameters(), function.returnType.findLLVMType(forReturnType: true)))
        guard function.varargs || function.parameters.count != argumentGrid.count || argumentGrid.contains(false) else {
            // trivial
            return GRPHTypes.funcref.constant(values: [generator.builder.buildBitCast(fn, type: PointerType.toVoid), GRPHTypes.type.null(), PointerType.toVoid.null()])
        }
        throw GRPHCompileError(type: .unsupported, message: "Function pointer requires thunk")
    }
    
    var ownership: Ownership {
        // only lambdas need reference counting as funcrefs
        .trivial
    }
}
