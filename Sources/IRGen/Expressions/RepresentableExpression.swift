//
//  RepresentableExpression.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 26/01/2022.
//  Copyright © 2022 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

protocol RepresentableExpression: Expression {
    func build(generator: IRGenerator) throws -> IRValue
}

protocol RepresentableAssignableExpression: RepresentableExpression, AssignableExpression {
    func getPointer(generator: IRGenerator) throws -> IRValue
}

extension Expression {
    func tryBuilding(generator: IRGenerator) throws -> IRValue {
        if let expression = self as? RepresentableExpression {
            return try expression.build(generator: generator)
        } else {
            throw GRPHCompileError(type: .unsupported, message: "Expression of type \(type(of: self)) is not supported in IRGen mode")
        }
    }
}
