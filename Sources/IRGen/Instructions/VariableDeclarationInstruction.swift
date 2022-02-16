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
        let initializer = try value.tryBuilding(generator: generator, expect: type as! RepresentableGRPHType)
        let type = try type.findLLVMType()
        if global {
            let glob: Global
            let mangled = generator.mangleNames ? "_GV4none\(name.count)\(name)" : name
            if initializer.isConstant {
                glob = generator.builder.addGlobal(mangled, initializer: initializer)
                if constant {
                    glob.isGlobalConstant = true
                }
            } else {
                glob = generator.builder.addGlobal(mangled, initializer: type.undef())
                generator.builder.buildStore(initializer, to: glob)
            }
            generator.globalContext?.insert(variable: Variable(name: name, ref: .global(glob)))
        } else if constant {
            generator.currentContext?.insert(variable: Variable(name: name, ref: .value(initializer)))
        } else {
            let variable = generator.insertAlloca(type: type, name: name)
            generator.builder.buildStore(initializer, to: variable)
            generator.currentContext?.insert(variable: Variable(name: name, ref: .stack(variable)))
        }
    }
}

extension IRGenerator {
    func insertAlloca(type: IRType, name: String = "") -> IRInstruction{
        let pos = builder.insertBlock!
        builder.positionBefore(builder.currentFunction!.firstBlock!.lastInstruction!)
        defer {
            builder.positionAtEnd(of: pos)
        }
        return builder.buildAlloca(type: type, name: name)
    }
}
