//
//  VariableExpression.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 28/01/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

extension VariableExpression: RepresentableAssignableExpression {
    func build(generator: IRGenerator) throws -> IRValue {
        guard let variable = generator.currentContext?.findVariable(named: name) else {
            throw GRPHCompileError(type: .undeclared, message: "Variable was not found")
        }
        return try variable.getContent(generator: generator)
    }
    
    func getPointer(generator: IRGenerator) throws -> IRValue {
        guard let variable = generator.currentContext?.findVariable(named: name) else {
            throw GRPHCompileError(type: .undeclared, message: "Variable was not found")
        }
        return try variable.getPointer(generator: generator)
    }
    
    var ownership: Ownership {
        .borrowed
    }
}
