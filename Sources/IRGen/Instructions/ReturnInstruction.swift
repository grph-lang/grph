//
//  ReturnInstruction.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 10/02/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues

extension ReturnInstruction: RepresentableInstruction {
    func build(generator: IRGenerator) throws {
        let fn = generator.currentContext!.currentFunction!
        
        // retain return value
        let ret = try (value ?? fn.returnDefault)?.owned(generator: generator, expect: fn.generated.returnType)
        
        // cleanup broken blocks
        var ctx = generator.currentContext
        while ctx != nil {
            if let ctx = ctx as? VariableOwningIRContext {
                try ctx.cleanup(generator: generator)
            }
            if ctx is FunctionIRContext {
                break
            }
            ctx = ctx?.parent
        }
        
        if value != nil {
            generator.builder.buildRet(ret!)
        } else {
            if fn.generated.returnType.isTheVoid {
                generator.builder.buildRetVoid()
            } else if fn.returnDefault != nil {
                generator.builder.buildRet(ret!)
            } else {
                // this would be a compiler error upstream
                preconditionFailure()
            }
        }
        let next = generator.builder.currentFunction!.appendBasicBlock(named: "unreachable")
        generator.builder.positionAtEnd(of: next)
    }
}
