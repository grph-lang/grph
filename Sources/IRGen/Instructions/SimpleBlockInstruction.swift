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
        try generator.buildSimpleBlock(label: label ?? "block", for: self)
    }
}

extension ElseBlock: RepresentableInstruction {
    func build(generator: IRGenerator) throws {
        try generator.buildSimpleBlock(label: label ?? "else", for: self)
    }
}

extension IRGenerator {
    func buildSimpleBlock(label: String, for block: BlockInstruction) throws {
        let newBlock = builder.currentFunction!.appendBasicBlock(named: label)
        let postBlock = builder.currentFunction!.appendBasicBlock(named: "\(label).post")
        
        builder.buildBr(newBlock)
        
        builder.positionAtEnd(of: newBlock)
        try block.buildChildren(generator: self)
        builder.buildBr(postBlock)
        
        builder.positionAtEnd(of: postBlock)
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
