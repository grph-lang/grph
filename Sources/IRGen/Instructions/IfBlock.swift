//
//  IfBlock.swift
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

extension IfBlock: RepresentableInstruction {
    func build(generator: IRGenerator) throws {
        let bodyBlock = generator.builder.currentFunction!.appendBasicBlock(named: label ?? "if")
        try generator.buildIfBlock(label: label, fallbackLabel: "if", for: self, condition: condition, elseBranch: elseBranch, bodyBlock: bodyBlock)
    }
}

extension ElseIfBlock: RepresentableElseLikeBlock {
    func createFallthroughBlock(generator: IRGenerator, fall: BasicBlock) -> BasicBlock {
        return generator.builder.currentFunction!.appendBasicBlock(named: label ?? "elseif")
    }
    
    func build(generator: IRGenerator, fallthroughBlock: BasicBlock) throws {
        try generator.buildIfBlock(label: label, fallbackLabel: "elseif", for: self, condition: condition, elseBranch: elseBranch, bodyBlock: fallthroughBlock)
    }
}

extension IRGenerator {
    fileprivate func buildIfBlock(label _label: String?, fallbackLabel: String, for block: BlockInstruction, condition: Expression, elseBranch: ElseLikeBlock?, bodyBlock: BasicBlock) throws {
        let label = _label ?? fallbackLabel
        let postBlock = builder.currentFunction!.appendBasicBlock(named: "\(label).post")
        let elseBlock: BasicBlock
        let ctx: BlockIRContext
        
        if let elseBranch = elseBranch as? RepresentableElseLikeBlock {
            elseBlock = builder.currentFunction!.appendBasicBlock(named: "\(label).else")
            ctx = BlockIRContext(parent: currentContext, label: _label,
                                 break: postBlock, fall: elseBlock, fallthrough: elseBranch.createFallthroughBlock(generator: self, fall: elseBlock))
        } else {
            elseBlock = postBlock
            ctx = BlockIRContext(parent: currentContext, label: _label, break: postBlock)
        }
        
        builder.buildCondBr(condition: try condition.tryBuilding(generator: self, expect: SimpleType.boolean), then: bodyBlock, else: elseBlock)
        
        builder.positionAtEnd(of: bodyBlock)
        try block.buildChildren(generator: self, context: ctx)
        builder.buildBr(postBlock)
        
        if let elseBranch = elseBranch {
            builder.positionAtEnd(of: elseBlock)
            guard let elseBranch = elseBranch as? RepresentableElseLikeBlock else {
                throw GRPHCompileError(type: .unsupported, message: "Else branch of type \(type(of: elseBranch)) is not supported in IRGen mode")
            }
            try elseBranch.build(generator: self, fallthroughBlock: ctx.fallthroughDestination!)
            builder.buildBr(postBlock)
        }
        
        builder.positionAtEnd(of: postBlock)
    }
}
