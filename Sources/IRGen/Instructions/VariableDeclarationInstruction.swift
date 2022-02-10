//
//  VariableDeclarationInstruction.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 28/01/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

extension VariableDeclarationInstruction: RepresentableInstruction {
    func build(generator: IRGenerator) throws {
        let initializer = try value.tryBuilding(generator: generator)
        let type = try type.findLLVMType()
        if global {
            let glob: Global
            if constant, initializer.isConstant {
                glob = generator.builder.addGlobal("_G4none\(name.count)\(name)", initializer: initializer)
                glob.isGlobalConstant = true
            } else {
                glob = generator.builder.addGlobal("_G4none\(name.count)\(name)", initializer: type.undef())
                generator.builder.buildStore(initializer, to: glob)
            }
            generator.globalContext?.insert(variable: Variable(name: name, ref: .global(glob)))
        } else if constant {
            generator.currentContext?.insert(variable: Variable(name: name, ref: .value(initializer)))
        } else {
            let pos = generator.builder.insertBlock!
            generator.builder.positionBefore(generator.builder.currentFunction!.firstBlock!.lastInstruction!)
            let variable = generator.builder.buildAlloca(type: type, name: name)
            generator.builder.positionAtEnd(of: pos)
            
            generator.builder.buildStore(initializer, to: variable)
            generator.currentContext?.insert(variable: Variable(name: name, ref: .stack(variable)))
        }
    }
}
