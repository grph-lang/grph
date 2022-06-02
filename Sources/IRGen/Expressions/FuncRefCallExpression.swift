//
//  FuncRefCallExpression.swift
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

extension FuncRefCallExpression: RepresentableExpression {
    func build(generator: IRGenerator) throws -> IRValue {
        let type = (exp.getType() as! FuncRefType)
        return try exp.borrow(generator: generator, expect: nil) { funcref in
            var handles: [() -> Void] = []
            defer {
                handles.forEach { $0() }
            }
            let args = try self.values.enumerated().map { i, val in
                try val!.borrowWithHandle(generator: generator, expect: type.parameterTypes[i], handles: &handles)
            }
            // TODO: pass captured data as first argument when type != NULL
            let fn = try generator.builder.buildBitCast(generator.builder.buildExtractValue(funcref, index: 0), type: PointerType(pointee: FunctionType(type.llvmParameters(), type.returnType.findLLVMType(forReturnType: true))))
            return generator.builder.buildCall(fn, args: args)
        }
    }
    
    var ownership: Ownership {
        .owned
    }
}
