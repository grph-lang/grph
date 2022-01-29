//
//  SimpleBlockInstruction.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 29/01/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues

extension SimpleBlockInstruction: RepresentableInstruction {
    func build(generator: IRGenerator) throws {
        let newBlock = generator.builder.currentFunction!.appendBasicBlock(named: label ?? "")
        generator.builder.buildBr(newBlock)
        generator.builder.positionAtEnd(of: newBlock)
        
        try buildChildren(generator: generator)
    }
}

extension BlockInstruction {
    func buildChildren(generator: IRGenerator) throws {
        generator.currentContext = VariableOwningIRContext(parent: generator.currentContext)
        defer {
            generator.currentContext = generator.currentContext?.parent
        }
        try children.buildAll(generator: generator)
    }
}
