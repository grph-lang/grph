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
        
        let allocas = fn.appendBasicBlock(named: "entry.allocas")
        builder.positionAtEnd(of: allocas)
        let entry = fn.appendBasicBlock(named: "entry")
        builder.buildBr(entry)
        builder.positionAtEnd(of: entry)
        
        for (i, var par) in fn.parameters.enumerated() {
            let param = generated.parameters[i]
            let name = param.name
            if let def = defaults[i] {
                par.name = "\(name).optional"
                
                let valueBranch = fn.appendBasicBlock(named: "\(name).exists")
                let emptyBranch = fn.appendBasicBlock(named: "\(name).empty")
                let mergeBranch = fn.appendBasicBlock(named: "\(name).merge")
                
                builder.buildCondBr(condition: builder.buildExtractValue(par, index: 0), then: valueBranch, else: emptyBranch)
                
                builder.positionAtEnd(of: valueBranch)
                let unwrapped = param.type.copy(generator: generator, value: builder.buildExtractValue(par, index: 1))
                builder.buildBr(mergeBranch)
                
                builder.positionAtEnd(of: emptyBranch)
                let defaulted = try def.owned(generator: generator, expect: param.type)
                builder.buildBr(mergeBranch)
                
                builder.positionAtEnd(of: mergeBranch)
                let phi = builder.buildPhi(try param.type.findLLVMType(), name: name)
                phi.addIncoming([
                    (unwrapped, valueBranch),
                    (defaulted, emptyBranch)
                ])
                ctx.insert(variable: Variable(name: name, ref: .ownedValue(phi, cleanup: param.type.destroy(generator:value:))))
            } else {
                par.name = name
                ctx.insert(variable: Variable(name: name, ref: (generated.trueParamTypes[i] as! RepresentableGRPHType).representationMode == .existential ? .reference(par) : .borrowedValue(par)))
            }
        }
        
        try children.buildAll(generator: generator)
        
        if let rd = returnDefault {
            let built = try rd.owned(generator: generator, expect: generated.returnType)
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
