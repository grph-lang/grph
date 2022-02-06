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
        let value: IRValue
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
            value = glob
        } else if constant {
            generator.currentContext?.insert(variable: Variable(name: name, ref: .value(initializer)))
            value = initializer
        } else {
            let variable = generator.builder.buildAlloca(type: type, name: name)
            generator.builder.buildStore(initializer, to: variable)
            generator.currentContext?.insert(variable: Variable(name: name, ref: .stack(variable)))
            value = variable
        }
        if !global {
            generator.debug.buildDeclare(of: value, atEndOf: generator.builder.insertBlock!, metadata: generator.debug.buildLocalVariable(named: name, scope: generator.currentContext!.currentScope, file: generator.debugFile, line: line, type: generator.debug.buildBasicType(named: self.type.string, encoding: .signed, flags: [], size: generator.builder.module.dataLayout.abiSize(of: type)/8), alignment: generator.builder.module.dataLayout.abiAlignment(of: type)), expr: generator.debug.buildExpression([]), location: generator.debug.buildDebugLocation(at: (line: line, column: 0), in: generator.currentContext!.currentScope))
        }
    }
}
