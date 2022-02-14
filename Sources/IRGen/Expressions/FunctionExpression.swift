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
        return generator.builder.buildCall(fn, args: try values.map {
            // TODO wrap in optional, varargs etc
            if let arg = $0 {
                return try arg.tryBuilding(generator: generator)
            }
            throw GRPHCompileError(type: .unsupported, message: "Optionals are not supported in IRGen mode")
        })
    }
}

extension Parametrable {
    func llvmParameters() throws -> [IRType] {
        try parameters.enumerated().map { i, par in
            // TODO handle varargs, optional params
            return try par.type.findLLVMType()
        }
    }
}

public extension GRPHValues.Function {
    func getMangledName(generator: IRGenerator?) -> String {
        switch storage {
        case .block(_):
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
