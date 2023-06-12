//
//  MethodExpression.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 12/06/2023.
//  Copyright © 2023 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

typealias Method = GRPHValues.Method

extension MethodExpression: RepresentableExpression {
    func build(generator: IRGenerator) throws -> IRValue {
        let fn = try generator.module.getOrInsertFunction(named: "grphm_\(method.inType.string)_\(method.name)", type: method.llvmFunctionType())
        return try FunctionExpression.buildCall(generator: generator, fn: fn, function: method, values: [on] + values)
    }
    
    var ownership: Ownership {
        .owned
    }
}
