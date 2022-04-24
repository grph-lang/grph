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
        // ownership is transferred, and no type conversion is occurring
        return generator.builder.buildExtractValue(try exp.tryBuildingWithoutCaringAboutAnythingForNow(generator: generator), index: 1)
    }
    
    var ownership: Ownership {
        (exp as! RepresentableExpression).ownership
    }
}

extension NullExpression: RepresentableExpression {
    func build(generator: IRGenerator) throws -> IRValue {
        try (getType() as! OptionalType).asLLVM().null()
    }
    
    var ownership: Ownership {
        .trivial
    }
}
