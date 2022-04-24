//
//  UnaryExpression.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 29/01/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

extension UnaryExpression: RepresentableExpression {
    func build(generator: IRGenerator) throws -> IRValue {
        // type is always trivial and statically correct (int, float or num)
        let value = try exp.owned(generator: generator, expect: nil)
        switch op {
        case .bitwiseComplement, .not: // ~ and ! are the same, but with different int width
            return generator.builder.buildNot(value)
        case .opposite:
            // TODO: value can here be integer (OK), float (OK), but also the num existential (NOT OK!)
            return generator.builder.buildNeg(value)
        }
    }
    
    var ownership: Ownership {
        .trivial
    }
}
