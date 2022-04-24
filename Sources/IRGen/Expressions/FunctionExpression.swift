//
//  FunctionExpression.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 26/01/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

extension FunctionExpression: RepresentableExpression {
    func build(generator: IRGenerator) throws -> IRValue {
        let fn = try generator.builder.module.getOrInsertFunction(named: function.getMangledName(generator: generator), type: FunctionType(function.llvmParameters(), function.returnType.findLLVMType(forReturnType: true)))
        var handles: [() -> Void] = []
        defer {
            handles.forEach { $0() }
        }
        return generator.builder.buildCall(fn, args: try function.parameters.enumerated().map { i, param in
            let raw: IRValue = try {
                let arg = values[safe: i]
                if i == function.parameters.indices.last, function.varargs {
                    let ret: IRValue
                    if i <= values.count {
                        ret = try param.type.inArray.buildNewArray(generator: generator, values: values[i...].map { $0! })
                    } else {
                        ret = try param.type.inArray.buildNewArray(generator: generator, values: [])
                    }
                    handles.append {
                        param.type.inArray.destroy(generator: generator, value: ret)
                    }
                    return ret
                }
                let value = try arg.map { arg in
                    return try arg.borrowWithHandle(generator: generator, expect: param.type as! RepresentableGRPHType, handles: &handles)
                }
                if param.optional {
                    return try value.wrapInOptional(generator: generator, type: param.type.optional)
                }
                return value!
            }()
            return function.trueParamTypes[i].paramCCWrap(generator: generator, value: raw)
        })
    }
    
    var ownership: Ownership {
        .owned
    }
}

extension Parametrable {
    var trueParamTypes: [GRPHType] {
        parameters.enumerated().map { i, par in
            if i == parameters.indices.last, varargs {
                return par.type.inArray
            }
            if par.optional {
                return par.type.optional
            }
            return par.type
        }
    }
    
    func llvmParameters() throws -> [IRType] {
        return try trueParamTypes.map {
            return try $0.findLLVMType(forParameter: true)
        }
    }
}

public extension GRPHValues.Function {
    func getMangledName(generator: IRGenerator?) -> String {
        switch storage {
        case .block(_), .external:
            if !(generator?.mangleNames ?? true) {
                return name
            }
            return "_GF\(ns.name.count)\(ns.name)\(name.count)\(name)"
        case .native:
            return "grph_\(ns.name)_\(name)"
        }
    }
}

extension LLVM.Module {
    func getOrInsertFunction(named name: String, type: @autoclosure () throws -> FunctionType) rethrows -> LLVM.Function {
        try self.function(named: name) ?? self.addFunction(name, type: try type())
    }
}
