//
//  CastExpression.swift
//  GRPH IRGen
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
        switch cast {
        case .strict(optional: _):
            // TODO: checked optional/throwing conversions
            guard let dest = to as? RepresentableGRPHType else {
                throw GRPHCompileError(type: .unsupported, message: "Type \(to) not supported in `as!`")
            }
            let val = try from.owned(generator: generator, expect: SimpleType.mixed)
            return try SimpleType.mixed.unsafeDowncast(generator: generator, to: dest, value: val)
        case .conversion(optional: let isOptional):
            return try from.borrow(generator: generator, expect: SimpleType.mixed) { val in
                if to.isTheMixed {
                    return val // `as mixed` just existentializes
                }
                let fn: LLVM.Function
                if let to = to as? GRPHValues.ArrayType {
                    fn = try to.generateConversionThunk(generator: generator)
                } else {
                    fn = try generator.builder.module.getOrInsertFunction(named: "grphas_\(to.string)", type: FunctionType([PointerType(pointee: GRPHTypes.existential)], to.optional.findLLVMType()))
                }
                let result = generator.builder.buildCall(fn, args: [SimpleType.mixed.paramCCWrap(generator: generator, value: val)])
                if isOptional {
                    return result
                } else {
                    // TODO: throw on null
                    return generator.builder.buildExtractValue(result, index: 1)
                }
            }
        case .typeCheck:
            // TODO: support reference types
            guard let dest = to as? RepresentableGRPHType,
                  dest.representationMode == .pureValue || dest.representationMode == .impureValue else {
                throw GRPHCompileError(type: .unsupported, message: "Type \(to) not supported in `is`")
            }
            return try from.borrow(generator: generator, expect: SimpleType.mixed) { val in
                let glob = dest.getTypeTableGlobalPtr(generator: generator)
                return generator.builder.buildICmp(
                    generator.builder.buildPointerDifference(generator.builder.buildExtractValue(val, index: 0), glob), 0, .equal)
            }
        }
    }
    
    var ownership: Ownership {
        .owned
    }
}

extension RepresentableGRPHType {
    func getTypeTableGlobal(generator: IRGenerator) -> Global {
        if let g = generator.builder.module.global(named: "typetable.\(self)") {
            return g
        }
        let typenameContent: [Int8] = [Int8(bitPattern: self.typeid)] + self.string.utf8CString
        var typename = generator.builder.addGlobal("", initializer: LLVM.ArrayType.constant(typenameContent, type: IntType.int8))
        typename.isGlobalConstant = true
        typename.linkage = .private
        typename.unnamedAddressKind = .global
        
        var vwt = generator.builder.addGlobal("", initializer: GRPHTypes.vwt.constant(values: [
            generator.builder.buildSizeOf(try! self.asLLVM()),
            generator.builder.buildAlignOf(try! self.asLLVM()),
            generator.module.getOrInsertFunction(named: self.vwt.copy, type: GRPHTypes.copyFunc),
            generator.module.getOrInsertFunction(named: self.vwt.destroy, type: GRPHTypes.destroyFunc),
            self.representationMode == .referenceType ? generator.module.getOrInsertFunction(named: self.vwt.destructor, type: GRPHTypes.deinitFunc) : PointerType(pointee: GRPHTypes.deinitFunc).null(),
        ]))
        vwt.isGlobalConstant = true
        vwt.linkage = .private
        vwt.unnamedAddressKind = .global
        
        var glob = generator.builder.addGlobal("typetable.\(self)", initializer: StructType.constant(values: [
            generator.builder.buildInBoundsGEP(typename, type: LLVM.ArrayType(elementType: IntType.int8, count: typenameContent.count), indices: [0, 1]),
            vwt
        ] + self.genericsVector.map { type in
            type.getTypeTableGlobal(generator: generator)
        } + [PointerType.toVoid.null()]))
        glob.isGlobalConstant = true
        glob.linkage = .linkOnceAny
        return glob
    }
    
    func getTypeTableGlobalPtr(generator: IRGenerator) -> IRValue {
        generator.builder.buildBitCast(getTypeTableGlobal(generator: generator), type: GRPHTypes.type)
    }
    
    /// transform anything into an existential
    private func existentialize(generator: IRGenerator, value: Expression) throws -> (IRValue, ownedCopy: Bool) {
        if self.representationMode == .existential {
            return (try value.tryBuildingWithoutCaringAboutAnythingForNow(generator: generator), false)
        }
        let glob = getTypeTableGlobal(generator: generator)
        
        let data = generator.insertAlloca(type: GRPHTypes.existentialData)
        // this shouldn't be needed (reset value to zero)
        generator.builder.buildStore(GRPHTypes.existentialData.null(), to: data)
        
        // TODO: handle types bigger than 3 words
        
        let dataErased = generator.builder.buildBitCast(data, type: PointerType(pointee: try self.asLLVM()))
        generator.builder.buildStore(try value.owned(generator: generator, expect: nil), to: dataErased)
        
        let constExt = GRPHTypes.existential.constant(values: [generator.builder.buildBitCast(glob, type: PointerType(pointee: IntType.int8)), GRPHTypes.existentialData.undef()])
        return (generator.builder.buildInsertValue(aggregate: constExt, element: generator.builder.buildLoad(data, type: GRPHTypes.existentialData), index: 1), true)
    }
    
    /// Cast from this type, to a parent type
    /// Don't call this directly, use `Expression.tryBuilding(generator:expect:)`
    func upcastDefault(generator: IRGenerator, to: RepresentableGRPHType, value: Expression) throws -> (IRValue, ownedCopy: Bool) {
        if self == to {
            return (try value.tryBuildingWithoutCaringAboutAnythingForNow(generator: generator), ownedCopy: false)
        }
        switch to.representationMode {
        case .pureValue, .impureValue:
            throw GRPHCompileError(type: .unsupported, message: "Tried to upcast unrelated type \(self) to \(to)")
        case .referenceType:
            guard self.representationMode == .referenceType else {
                throw GRPHCompileError(type: .unsupported, message: "Tried to upcast unrelated type \(self) to \(to)")
            }
            return (try value.tryBuildingWithoutCaringAboutAnythingForNow(generator: generator), ownedCopy: false) // same thing, aka a pointer to a box
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
        
        let dataErased = generator.builder.buildBitCast(data, type: PointerType(pointee: try to.asLLVM()))
        return generator.builder.buildLoad(dataErased, type: try to.asLLVM())
    }
}
