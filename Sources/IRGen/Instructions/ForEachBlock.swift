//
//  ForEachBlock.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 27/02/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

extension ForEachBlock: RepresentableInstruction {
    func build(generator: IRGenerator) throws {
        guard elseBranch == nil else {
            // TODO: foreach-else
            throw GRPHCompileError(type: .unsupported, message: "foreach-else")
//            return try buildWhileElse(generator: generator)
        }
        let label = label ?? "foreach"
        
        let preBlock = generator.builder.currentFunction!.appendBasicBlock(named: "\(label).pre")
        let condBlock = generator.builder.currentFunction!.appendBasicBlock(named: "\(label).cond")
        let bodyBlock = generator.builder.currentFunction!.appendBasicBlock(named: "\(label).body")
        let repeatBlock = generator.builder.currentFunction!.appendBasicBlock(named: "\(label).repeat")
        let postBlock = generator.builder.currentFunction!.appendBasicBlock(named: "\(label).post")
        
        generator.builder.buildBr(preBlock)
        
        generator.builder.positionAtEnd(of: preBlock)
        let subjectRef = try array.owned(generator: generator, expect: nil)
        let subject = generator.builder.buildBitCast(subjectRef, type: PointerType(pointee: GRPHTypes.arrayStruct))
        generator.builder.buildBr(condBlock)
        
        generator.builder.positionAtEnd(of: condBlock)
        let index = generator.builder.buildPhi(GRPHTypes.integer)
        let len = generator.builder.buildExtractValue(generator.builder.buildLoad(subject, type: GRPHTypes.arrayStruct), index: 1)
        generator.builder.buildCondBr(condition: generator.builder.buildICmp(index, len, .signedLessThan), then: bodyBlock, else: postBlock)
        
        generator.builder.positionAtEnd(of: bodyBlock)
        let elemType = (array.getType() as! GRPHValues.ArrayType).content
        let arrayBuf = generator.builder.buildExtractValue(generator.builder.buildLoad(subject, type: GRPHTypes.arrayStruct), index: 3)
        let arrayTypedBuf = try generator.builder.buildBitCast(arrayBuf, type: PointerType(pointee: elemType.findLLVMType()))
        let elem = generator.builder.buildGEP(arrayTypedBuf, type: try! elemType.findLLVMType(), indices: [index])
        let innerctx = BlockIRContext(parent: generator.currentContext, label: self.label, break: postBlock, continue: condBlock)
        innerctx.insert(variable: Variable(name: varName, ref: .reference(elem)))
        try buildChildren(generator: generator, context: innerctx)
        generator.builder.buildBr(repeatBlock)
        
        generator.builder.positionAtEnd(of: repeatBlock)
        let iNext = generator.builder.buildAdd(index, 1)
        generator.builder.buildBr(condBlock)
        
        index.addIncoming([
            (0, preBlock),
            (iNext, repeatBlock)
        ])
        
        generator.builder.positionAtEnd(of: postBlock)
        array.getType().destroy(generator: generator, value: subjectRef)
    }
}
