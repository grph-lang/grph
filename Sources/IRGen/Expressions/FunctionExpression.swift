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
        generator.builder.buildCall(generator.builder.addFunction(function.mangledName, type: FunctionType(try function.llvmParameters(), try function.returnType.findLLVMType())), args: try values.map {
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

extension GRPHValues.Function {
    var mangledName: String {
        switch storage {
        case .block(_):
            return "_G\(ns.name.count)\(ns.name)\(name.count)\(name)"
        case .native:
            return "grph_\(ns.name)_\(name)"
        }
    }
}
