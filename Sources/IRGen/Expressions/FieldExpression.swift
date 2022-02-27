//
//  FieldExpression.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 12/02/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

extension FieldExpression: RepresentableExpression {
    func build(generator: IRGenerator) throws -> IRValue {
        // writeable struct fields should use direct pointers instead
        let subject = try on.tryBuilding(generator: generator, expect: onType)
        
        switch (onType, field.name) {
        case (SimpleType.pos, "x"), (SimpleType.pos, "y"):
            return generator.builder.buildExtractValue(subject, index: field.name == "y" ? 1 : 0)
        case (is TupleType, let name):
            return generator.builder.buildExtractValue(subject, index: Int(name.dropFirst())!)
        case (is GRPHValues.ArrayType, "length"):
            return generator.builder.buildExtractValue(generator.builder.buildLoad(generator.builder.buildBitCast(subject, type: PointerType(pointee: GRPHTypes.arrayStruct)), type: GRPHTypes.arrayStruct), index: 2)
        default:
            let fn = try generator.builder.module.getOrInsertFunction(named: "grphp_\(onType.string)_\(field.name)_get", type: FunctionType([onType.findLLVMType()], field.type.findLLVMType()))
            return generator.builder.buildCall(fn, args: [subject])
        }
    }
}

extension FieldExpression: RepresentableAssignableExpression {
    func getPointer(generator: IRGenerator) throws -> IRValue {
        guard let on = on as? RepresentableAssignableExpression else {
            throw GRPHCompileError(type: .unsupported, message: "AssignableExpression of type \(type(of: on)) is not supported in IRGen mode")
        }
        let subject = try on.getPointer(generator: generator)
        
        switch (onType, field.name) {
        case (SimpleType.pos, "x"), (SimpleType.pos, "y"):
            return generator.builder.buildStructGEP(subject, type: GRPHTypes.pos, index: field.name == "y" ? 1 : 0)
        case (let tuple as TupleType, let name):
            return generator.builder.buildStructGEP(subject, type: try tuple.asLLVM(), index: Int(name.dropFirst())!)
        default:
            throw GRPHCompileError(type: .unsupported, message: "Field \(onType).\(field.name) is not assignable in IRGen mode")
        }
    }
}

extension ValueTypeExpression: RepresentableExpression {
    func build(generator: IRGenerator) throws -> IRValue {
        let val = try on.tryBuilding(generator: generator, expect: SimpleType.mixed)
        return generator.builder.buildExtractValue(val, index: 0)
    }
}
