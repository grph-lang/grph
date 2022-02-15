//
//  CastExpression.swift
//  GRPH
// 
//  Created by Emil Pedersen on 14/02/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

extension CastExpression: RepresentableExpression {
    func build(generator: IRGenerator) throws -> IRValue {
        let fn = try generator.builder.module.getOrInsertFunction(named: "grphas_\(to.string)", type: FunctionType([GRPHTypes.existential], to.findLLVMType()))
        let val = try from.tryBuilding(generator: generator, expect: SimpleType.mixed)
        return generator.builder.buildCall(fn, args: [val])
    }
}

extension RepresentableGRPHType {
    /// transform a pure value type into an existential
    private func existentialize(generator: IRGenerator, value: IRValue) throws -> IRValue {
        if self.representationMode == .existential {
            return value
        }
        guard let type = self.typeid else {
            throw GRPHCompileError(type: .unsupported, message: "Type \(self) cannot be placed in an existential")
        }
        var glob = generator.builder.addGlobal("irtype.\(self)", initializer: LLVM.ArrayType.constant(type, type: IntType.int8))
        glob.isGlobalConstant = true
        glob.linkage = .private
        let ptr = PointerType(pointee: IntType.int8)
        let cnt = LLVM.ArrayType.constant([ptr.null(), ptr.null(), ptr.null()], type: PointerType(pointee: IntType.int8))
        let mixed = GRPHTypes.existential.constant(values: [generator.builder.buildBitCast(glob, type: PointerType(pointee: IntType.int8)), GRPHTypes.existential.elementTypes[1].undef()])
        let elem = generator.builder.buildInsertValue(aggregate: cnt, element: generator.builder.buildIntToPtr(value, type: ptr), index: 0)
        return generator.builder.buildInsertValue(aggregate: mixed, element: elem, index: 1)
    }
    
    /// Cast from this type, to a parent type
    /// Don't call this directly, use `Expression.tryBuilding(generator:expect:)`
    func downcast(generator: IRGenerator, to: RepresentableGRPHType, value: IRValue) throws -> IRValue {
        if self == to {
            return value
        }
        switch to.representationMode {
        case .pureValue, .impureValue:
            throw GRPHCompileError(type: .unsupported, message: "Tried to downcast unrelated type \(self) to \(to)")
        case .referenceType:
            guard self.representationMode == .referenceType else {
                throw GRPHCompileError(type: .unsupported, message: "Tried to downcast unrelated type \(self) to \(to)")
            }
            return value // same thing, aka a pointer to a box
        case .existential:
            return try existentialize(generator: generator, value: value)
        }
    }
}
