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
    
    var ownership: Ownership { get }
}

protocol RepresentableAssignableExpression: RepresentableExpression, AssignableExpression {
    /// Gets the pointer to the data. When possible, only this function is called for compound assignments.
    /// The `value` from the block will only be accessible inside the closure, and will be invalidated when this function returns.
    func withPointer<T>(generator: IRGenerator, block: (_ value: IRValue) throws -> T) throws -> T
}

extension Expression {
    func tryBuildingWithoutCaringAboutAnythingForNow(generator: IRGenerator) throws -> IRValue {
        guard let expression = self as? RepresentableExpression else {
            throw GRPHCompileError(type: .unsupported, message: "Expression of type \(type(of: self)) is not supported in IRGen mode")
        }
        return try expression.build(generator: generator)
    }
    
    private func tryBuilding(generator: IRGenerator, expect: GRPHType) throws -> (IRValue, ownedCopy: Bool) {
        guard let expect = expect as? RepresentableGRPHType else {
            throw GRPHCompileError(type: .unsupported, message: "Type \(expect) is not supported in IRGen mode")
        }
        guard let from = self.getType() as? RepresentableGRPHType else {
            throw GRPHCompileError(type: .unsupported, message: "Type \(self.getType()) is not supported in IRGen mode")
        }
        return try from.upcast(generator: generator, to: expect, value: self)
    }
    
    private func tryBuildingSel(generator: IRGenerator, expect: GRPHType?) throws -> (IRValue, ownedCopy: Bool) {
        if let expect = expect {
            return try tryBuilding(generator: generator, expect: expect)
        } else {
            return (try tryBuildingWithoutCaringAboutAnythingForNow(generator: generator), ownedCopy: false)
        }
    }
    
    func borrow<T>(generator: IRGenerator, expect: GRPHType?, block: (_ value: IRValue) throws -> T) throws -> T {
        guard let self = self as? RepresentableExpression else {
            throw GRPHCompileError(type: .unsupported, message: "Expression of type \(type(of: self)) is not supported in IRGen mode")
        }
        let (built, ownedCopy) = try tryBuildingSel(generator: generator, expect: expect)
        switch ownedCopy ? .owned : self.ownership {
        case .owned:
            defer {
                (expect ?? getType()).destroy(generator: generator, value: built)
            }
            return try block(built)
        case .borrowed, .trivial:
            // already borrowed, nothing to do
            return try block(built)
        }
    }
    
    func borrowWithHandle(generator: IRGenerator, expect: GRPHType?, handles: inout [() -> Void]) throws -> IRValue {
        guard let self = self as? RepresentableExpression else {
            throw GRPHCompileError(type: .unsupported, message: "Expression of type \(type(of: self)) is not supported in IRGen mode")
        }
        let (built, ownedCopy) = try tryBuildingSel(generator: generator, expect: expect)
        switch ownedCopy ? .owned : self.ownership {
        case .owned:
            handles.append {
                (expect ?? getType()).destroy(generator: generator, value: built)
            }
            return built
        case .borrowed, .trivial:
            // already borrowed, nothing to do
            return built
        }
    }
    
    func owned(generator: IRGenerator, expect: GRPHType?) throws -> IRValue {
        guard let self = self as? RepresentableExpression else {
            throw GRPHCompileError(type: .unsupported, message: "Expression of type \(type(of: self)) is not supported in IRGen mode")
        }
        let (built, ownedCopy) = try tryBuildingSel(generator: generator, expect: expect)
        switch ownedCopy ? .owned : self.ownership {
        case .owned, .trivial:
            return built
        case .borrowed:
            return (expect ?? getType()).copy(generator: generator, value: built)
        }
    }
}
