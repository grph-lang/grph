//
//  AssignmentInstruction.swift
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

extension AssignmentInstruction: RepresentableInstruction {
    func build(generator: IRGenerator) throws {
        if let assigned = assigned as? RepresentableAssignableExpression {
            let ptr = try assigned.getPointer(generator: generator)
            generator.builder.buildStore(try value.tryBuilding(generator: generator), to: ptr)
        } else {
            throw GRPHCompileError(type: .unsupported, message: "AssignableExpression of type \(type(of: self)) is not supported in IRGen mode")
        }
    }
}
