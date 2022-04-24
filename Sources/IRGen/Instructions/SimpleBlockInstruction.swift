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
import LLVM

extension SimpleBlockInstruction: RepresentableInstruction {
    func build(generator: IRGenerator) throws {
        try generator.buildSimpleBlock(label: label, fallbackLabel:  "block", for: self)
    }
}

extension ElseBlock: RepresentableElseLikeBlock {
    func createFallthroughBlock(generator: IRGenerator, fall: BasicBlock) -> BasicBlock {
        return fall
    }
    
    func build(generator: IRGenerator, fallthroughBlock: BasicBlock) throws {
        try generator.buildSimpleBlock(label: label, fallbackLabel: "else", for: self)
    }
}

extension IRGenerator {
    fileprivate func buildSimpleBlock(label _label: String?, fallbackLabel: String, for block: BlockInstruction) throws {
        let label = _label ?? fallbackLabel
        let newBlock = builder.currentFunction!.appendBasicBlock(named: label)
        let postBlock = builder.currentFunction!.appendBasicBlock(named: "\(label).post")
        
        builder.buildBr(newBlock)
        
        builder.positionAtEnd(of: newBlock)
        try block.buildChildren(generator: self, context: BlockIRContext(parent: currentContext, label: _label, break: postBlock))
        builder.buildBr(postBlock)
        
        builder.positionAtEnd(of: postBlock)
    }
}

extension BlockInstruction {
    func buildChildren(generator: IRGenerator, context: BlockIRContext) throws {
        let restore = generator.currentContext
        generator.currentContext = context
        defer {
            generator.currentContext = restore
        }
        try children.buildAll(generator: generator)
        try context.cleanup(generator: generator)
    }
}
