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
        if let value = value {
            generator.builder.buildRet(try value.tryBuilding(generator: generator, expect: fn.generated.returnType))
        } else {
            if fn.generated.returnType.isTheVoid {
                generator.builder.buildRetVoid()
            } else if let def = fn.returnDefault {
                generator.builder.buildRet(try def.tryBuilding(generator: generator, expect: fn.generated.returnType))
            } else {
                // this would be a compiler error upstream
                preconditionFailure()
            }
        }
        let next = generator.builder.currentFunction!.appendBasicBlock(named: "unreachable")
        generator.builder.positionAtEnd(of: next)
    }
}
