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

extension FieldExpression {
    func getStructFieldIndex() -> Int? {
        switch (onType, field.name) {
        case (SimpleType.pos, "x"): return 0
        case (SimpleType.pos, "y"): return 1
        case (SimpleType.color, "red"): return 0
        case (SimpleType.color, "green"): return 1
        case (SimpleType.color, "blue"): return 2
        case (SimpleType.color, "falpha"): return 3
        case (is TupleType, let name):
            return Int(name.dropFirst())!
        default:
            return nil
        }
    }
    
    func typeExtract(generator: IRGenerator, value: IRValue) -> IRValue {
        switch (onType, field.name) {
        case (SimpleType.color, "red"), (SimpleType.color, "green"), (SimpleType.color, "blue"):
            return generator.builder.buildZExt(value, type: GRPHTypes.integer)
        case (SimpleType.color, "falpha"):
            return generator.builder.buildFPCast(value, type: GRPHTypes.float)
        default:
            return value
        }
    }
}

extension FieldExpression: RepresentableExpression {
    func build(generator: IRGenerator) throws -> IRValue {
        // writeable struct fields should use direct pointers instead
        return try on.borrow(generator: generator, expect: onType) { subject in
            if let index = getStructFieldIndex() {
                return typeExtract(generator: generator, value: generator.builder.buildExtractValue(subject, index: index))
            }
            switch (onType, field.name) {
            case (is GRPHValues.ArrayType, "length"):
                return generator.builder.buildExtractValue(generator.builder.buildLoad(generator.builder.buildBitCast(subject, type: PointerType(pointee: GRPHTypes.arrayStruct)), type: GRPHTypes.arrayStruct), index: 1)
            default:
                let fn = try generator.builder.module.getOrInsertFunction(named: "grphp_\(onType.string)_\(field.name)_get", type: FunctionType([onType.findLLVMType(forParameter: true)], field.type.findLLVMType()))
                return generator.builder.buildCall(fn, args: [onType.paramCCWrap(generator: generator, value: subject)])
            }
        }
    }
    
    var ownership: Ownership {
        .owned
    }
}

extension FieldExpression: RepresentableAssignableExpression {
    func getPointer(generator: IRGenerator) throws -> IRValue {
        guard let on = on as? RepresentableAssignableExpression else {
            throw GRPHCompileError(type: .unsupported, message: "AssignableExpression of type \(type(of: on)) is not supported in IRGen mode")
        }
        let subject = try on.getPointer(generator: generator)
        
        if let index = getStructFieldIndex() {
            return generator.builder.buildStructGEP(subject, type: try (onType as! RepresentableGRPHType).asLLVM(), index: index)
        }
        throw GRPHCompileError(type: .unsupported, message: "Field \(onType).\(field.name) is not assignable in IRGen mode")
    }
}

extension ValueTypeExpression: RepresentableExpression {
    func build(generator: IRGenerator) throws -> IRValue {
        return try on.borrow(generator: generator, expect: SimpleType.mixed) { val in
            return generator.builder.buildExtractValue(val, index: 0)
        }
    }
    
    var ownership: Ownership {
        .trivial
    }
}
