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
        // TODO: optional conversions and throwing ones
        switch cast {
        case .strict(optional: _):
            guard let dest = to as? RepresentableGRPHType else {
                throw GRPHCompileError(type: .unsupported, message: "Type \(to) not supported in `is`")
            }
            let val = try from.tryBuilding(generator: generator, expect: SimpleType.mixed)
            return try SimpleType.mixed.unsafeDowncast(generator: generator, to: dest, value: val)
        case .conversion(optional: _):
            let fn = try generator.builder.module.getOrInsertFunction(named: "grphas_\(to.string)", type: FunctionType([GRPHTypes.existential], to.findLLVMType()))
            let val = try from.tryBuilding(generator: generator, expect: SimpleType.mixed)
            return generator.builder.buildCall(fn, args: [val])
        case .typeCheck:
            // TODO: support reference types and non trivial types (optionals, arrays, tuples etc)
            guard let dest = to as? RepresentableGRPHType,
                  dest.isTrivial else {
                throw GRPHCompileError(type: .unsupported, message: "Type \(to) not supported in `is`")
            }
            let val = try from.tryBuilding(generator: generator, expect: SimpleType.mixed)
            return generator.builder.buildICmp(
                generator.builder.buildLoad(generator.builder.buildExtractValue(val, index: 0), type: IntType.int8), dest.typeid![0], .equal)
        }
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
        
        let data = generator.insertAlloca(type: GRPHTypes.existentialData)
        // this shouldn't be needed (reset value to zero)
        generator.builder.buildStore(GRPHTypes.existentialData.null(), to: data)
        
        let dataErased = generator.builder.buildBitCast(data, type: PointerType(pointee: self.asLLVM()))
        generator.builder.buildStore(value, to: dataErased)
        
        let constExt = GRPHTypes.existential.constant(values: [generator.builder.buildBitCast(glob, type: PointerType(pointee: IntType.int8)), GRPHTypes.existentialData.undef()])
        return generator.builder.buildInsertValue(aggregate: constExt, element: generator.builder.buildLoad(data, type: GRPHTypes.existentialData), index: 1)
    }
    
    /// Cast from this type, to a parent type
    /// Don't call this directly, use `Expression.tryBuilding(generator:expect:)`
    func upcast(generator: IRGenerator, to: RepresentableGRPHType, value: IRValue) throws -> IRValue {
        if self == to {
            return value
        }
        switch to.representationMode {
        case .pureValue, .impureValue:
            throw GRPHCompileError(type: .unsupported, message: "Tried to upcast unrelated type \(self) to \(to)")
        case .referenceType:
            guard self.representationMode == .referenceType else {
                throw GRPHCompileError(type: .unsupported, message: "Tried to upcast unrelated type \(self) to \(to)")
            }
            return value // same thing, aka a pointer to a box
        case .existential:
            return try existentialize(generator: generator, value: value)
        }
    }
    
    /// Cast from this (existential) type, to a subtype
    /// This casting is unsafe! it does no checks on the actual type
    func unsafeDowncast(generator: IRGenerator, to: RepresentableGRPHType, value: IRValue) throws -> IRValue {
        if self.representationMode != .existential {
            return value
        }
        let data = generator.insertAlloca(type: GRPHTypes.existentialData)
        // this shouldn't be needed (reset value to zero)
        generator.builder.buildStore(generator.builder.buildExtractValue(value, index: 1), to: data)
        
        let dataErased = generator.builder.buildBitCast(data, type: PointerType(pointee: to.asLLVM()))
        return generator.builder.buildLoad(dataErased, type: to.asLLVM())
    }
    
    /// A type is trivial if it is:
    ///  - a builtin
    ///  - a value type (pure or impure)
    var isTrivial: Bool {
        (self.representationMode == .pureValue || self.representationMode == .impureValue) && self.typeid?.count == 1
    }
}
