//
//  FieldExpression.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 12/02/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

extension FieldExpression: RepresentableExpression {
    func build(generator: IRGenerator) throws -> IRValue {
        // writeable struct fields should use direct pointers instead
        let subject = try on.tryBuilding(generator: generator)
        let fn = try generator.builder.module.getOrInsertFunction(named: "grphp_\(onType.string)_\(field.name)_get", type: FunctionType([onType.findLLVMType()], field.type.findLLVMType()))
        return generator.builder.buildCall(fn, args: [subject])
    }
}
