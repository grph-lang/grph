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
    /// Gets the pointer to the data. When possible, only this function is called for compound assignments.
    func getPointer(generator: IRGenerator) throws -> IRValue
}

extension Expression {
    func tryBuildingWithoutCaringAboutType(generator: IRGenerator) throws -> IRValue {
        guard let expression = self as? RepresentableExpression else {
            throw GRPHCompileError(type: .unsupported, message: "Expression of type \(type(of: self)) is not supported in IRGen mode")
        }
        return try expression.build(generator: generator)
    }
    
    func tryBuilding(generator: IRGenerator, expect: GRPHType) throws -> IRValue {
        guard let expect = expect as? RepresentableGRPHType else {
            throw GRPHCompileError(type: .unsupported, message: "Type \(expect) is not supported in IRGen mode")
        }
        guard let from = self.getType() as? RepresentableGRPHType else {
            throw GRPHCompileError(type: .unsupported, message: "Type \(self.getType()) is not supported in IRGen mode")
        }
        return try from.upcast(generator: generator, to: expect, value: self)
    }
}
