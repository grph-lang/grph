//
//  WhileBlock.swift
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

extension WhileBlock: RepresentableInstruction {
    func build(generator: IRGenerator) throws {
        
        guard elseBranch == nil else {
            return try buildWhileElse(generator: generator)
        }
        
        let condBlock = generator.builder.currentFunction!.appendBasicBlock(named: label.map { "\($0).cond"} ?? "cond")
        let whileBlock = generator.builder.currentFunction!.appendBasicBlock(named: label.map { "\($0).body"} ?? "body")
        let postBlock = generator.builder.currentFunction!.appendBasicBlock(named: label.map { "\($0).post"} ?? "post")
        
        generator.builder.buildBr(condBlock)
        
        generator.builder.positionAtEnd(of: condBlock)
        generator.builder.buildCondBr(condition: try condition.tryBuilding(generator: generator, expect: SimpleType.boolean), then: whileBlock, else: postBlock)
        
        generator.builder.positionAtEnd(of: whileBlock)
        try buildChildren(generator: generator, context: BlockIRContext(parent: generator.currentContext, label: self.label, break: postBlock, continue: condBlock))
        generator.builder.buildBr(condBlock)
        
        generator.builder.positionAtEnd(of: postBlock)
    }
    
    func buildWhileElse(generator: IRGenerator) throws {
        let label = label ?? "while"
        
        let entryBlock = generator.builder.currentFunction!.appendBasicBlock(named: "\(label).entry")
        let repeatBlock = generator.builder.currentFunction!.appendBasicBlock(named: "\(label).repeat")
        let condBlock = generator.builder.currentFunction!.appendBasicBlock(named: "\(label).cond")
        let bodyBlock = generator.builder.currentFunction!.appendBasicBlock(named: "\(label).body")
        let elseCheckBlock = generator.builder.currentFunction!.appendBasicBlock(named: "\(label).elseCheck")
        let elseBlock = generator.builder.currentFunction!.appendBasicBlock(named: "\(label).else")
        let postBlock = generator.builder.currentFunction!.appendBasicBlock(named: "\(label).post")
        
        guard let elseBranch = elseBranch as? RepresentableElseLikeBlock else {
            throw GRPHCompileError(type: .unsupported, message: "Else branch of type \(type(of: elseBranch)) is not supported in IRGen mode")
        }
        let fallthroughBlock = elseBranch.createFallthroughBlock(generator: generator, fall: elseBlock)
        
        generator.builder.buildBr(entryBlock)
        
        generator.builder.positionAtEnd(of: entryBlock)
        generator.builder.buildBr(condBlock)
        
        generator.builder.positionAtEnd(of: repeatBlock)
        generator.builder.buildBr(condBlock)
        
        generator.builder.positionAtEnd(of: condBlock)
        let phi = generator.builder.buildPhi(IntType.int1)
        phi.addIncoming([
            (IntType.int1.constant(1), entryBlock),
            (IntType.int1.constant(0), repeatBlock)
        ])
        let condition = try condition.tryBuilding(generator: generator, expect: SimpleType.boolean)
        generator.builder.buildCondBr(condition: condition, then: bodyBlock, else: elseCheckBlock)
        
        generator.builder.positionAtEnd(of: bodyBlock)
        try buildChildren(generator: generator, context: BlockIRContext(parent: generator.currentContext, label: self.label, break: postBlock, continue: repeatBlock, fall: elseBlock, fallthrough: fallthroughBlock))
        generator.builder.buildBr(repeatBlock)
        
        generator.builder.positionAtEnd(of: elseCheckBlock)
        generator.builder.buildCondBr(condition: phi, then: elseBlock, else: postBlock)
        
        generator.builder.positionAtEnd(of: elseBlock)
        try elseBranch.build(generator: generator, fallthroughBlock: fallthroughBlock)
        generator.builder.buildBr(postBlock)
        
        generator.builder.positionAtEnd(of: postBlock)
    }
}
