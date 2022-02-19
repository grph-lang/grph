//
//  UnboxExpression.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 19/02/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

extension UnboxExpression: RepresentableExpression {
    func build(generator: IRGenerator) throws -> IRValue {
        // TODO: throw on null
        generator.builder.buildExtractValue(try exp.tryBuilding(generator: generator, expect: exp.getType()), index: 1)
    }
}

extension NullExpression: RepresentableExpression {
    func build(generator: IRGenerator) throws -> IRValue {
        try (getType() as! OptionalType).asLLVM().null()
    }
}
