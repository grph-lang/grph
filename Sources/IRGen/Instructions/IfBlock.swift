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
        try generator.buildIfBlock(label: label ?? "if", for: self, condition: condition, elseBranch: elseBranch)
    }
}

extension ElseIfBlock: RepresentableInstruction {
    func build(generator: IRGenerator) throws {
        try generator.buildIfBlock(label: label ?? "elseif", for: self, condition: condition, elseBranch: elseBranch)
    }
}

extension IRGenerator {
    fileprivate func buildIfBlock(label: String, for block: BlockInstruction, condition: Expression, elseBranch: ElseLikeBlock?) throws {
        let bodyBlock = builder.currentFunction!.appendBasicBlock(named: label)
        let postBlock = builder.currentFunction!.appendBasicBlock(named: "\(label).post")
        let elseBlock: BasicBlock
        
        if elseBranch != nil {
            elseBlock = builder.currentFunction!.appendBasicBlock(named: "\(label).else")
        } else {
            elseBlock = postBlock
        }
        
        builder.buildCondBr(condition: try condition.tryBuilding(generator: self), then: bodyBlock, else: elseBlock)
        
        builder.positionAtEnd(of: bodyBlock)
        try block.buildChildren(generator: self)
        builder.buildBr(postBlock)
        
        if let elseBranch = elseBranch {
            builder.positionAtEnd(of: elseBlock)
            guard let elseBranch = elseBranch as? RepresentableInstruction else {
                throw GRPHCompileError(type: .unsupported, message: "Else branch of type \(type(of: elseBranch)) is not supported in IRGen mode")
            }
            try elseBranch.build(generator: self)
            builder.buildBr(postBlock)
        }
        
        builder.positionAtEnd(of: postBlock)
    }
}
