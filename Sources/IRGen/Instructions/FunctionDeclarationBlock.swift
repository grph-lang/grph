//
//  FunctionDeclarationBlock.swift
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

extension FunctionDeclarationBlock: RepresentableInstruction {
    func build(generator: IRGenerator) throws {
        if case .external = generated.storage {
            return
        }
        let ctx = FunctionIRContext(parent: generator.globalContext, astNode: self)
        let restoreCtx = generator.currentContext
        let restorePos = generator.builder.insertBlock!
        let builder = generator.builder
        generator.currentContext = ctx
        defer {
            generator.currentContext = restoreCtx
            generator.builder.positionAtEnd(of: restorePos)
        }
        
        let fn = try builder.addFunction(generated.getMangledName(generator: generator), type: FunctionType(generated.llvmParameters(), generated.returnType.findLLVMType(forReturnType: true)))
        for (i, var par) in fn.parameters.enumerated() {
            let name = generated.parameters[i].name
            par.name = name
            ctx.insert(variable: Variable(name: name, ref: .value(par)))
        }
        let allocas = fn.appendBasicBlock(named: "entry.allocas")
        builder.positionAtEnd(of: allocas)
        let entry = fn.appendBasicBlock(named: "entry")
        builder.buildBr(entry)
        builder.positionAtEnd(of: entry)
        
        try children.buildAll(generator: generator)
        
        if let rd = returnDefault {
            let built = try rd.tryBuilding(generator: generator, expect: generated.returnType)
            if generated.returnType.isTheVoid {
                builder.buildRetVoid()
            } else {
                builder.buildRet(built)
            }
        } else {
            if generated.returnType.isTheVoid {
                builder.buildRetVoid()
            } else {
                // TODO: throw exception.
                // For now, it is undefined behaviour to not specify a return value for a non-void function
                builder.buildUnreachable()
            }
        }
    }
}
