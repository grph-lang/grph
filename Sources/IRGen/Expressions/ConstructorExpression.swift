//
//  ConstructorExpression.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 19/02/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

extension ConstructorExpression: RepresentableExpression {
    func build(generator: IRGenerator) throws -> IRValue {
        switch constructor.storage {
        case .generic(signature: "{T}(T wrapped...)"), .generic(signature: "funcref<T><>(T wrapped)"):
            let type = constructor.type as! GRPHValues.ArrayType
            return try type.buildNewArray(generator: generator, values: values.map { $0! })
        case .generic(signature: "T?(T wrapped?)"):
            let type = constructor.type as! OptionalType
            return try values[safe: 0].map {
                try $0.owned(generator: generator, expect: type.wrapped)
            }.wrapInOptional(generator: generator, type: type)
        case .generic(signature: "tuple(T wrapped...)"):
            let type = constructor.type as! TupleType
            return try type.content.indices.reduce(try type.asLLVM().undef()) { (curr, i) in
                return try generator.builder.buildInsertValue(aggregate: curr, element: values[i]!.owned(generator: generator, expect: type.content[i]), index: i)
            }
        case .native:
            preconditionFailure("constructors not implemented")
        case .generic(signature: let sig):
            preconditionFailure("Generic constructor with signature \(sig) not found")
        }
    }
    
    var ownership: Ownership {
        .owned
    }
}


extension Optional where Wrapped == IRValue {
    func wrapInOptional(generator: IRGenerator, type: OptionalType) throws -> IRValue {
        if let wrapped = self {
            return try generator.builder.buildInsertValue(aggregate: type.getLLVMType().constant(values: [true, type.wrapped.findLLVMType().undef()]), element: wrapped, index: 1)
        } else {
            return try type.getLLVMType().null()
        }
    }
}
