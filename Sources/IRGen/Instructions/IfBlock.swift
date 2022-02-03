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
        let postBlock = generator.builder.currentFunction!.appendBasicBlock(named: label.map { "\($0).post"} ?? "")
        let elseBlock: BasicBlock
        
        if elseBranch != nil {
            elseBlock = generator.builder.currentFunction!.appendBasicBlock(named: label.map { "\($0).else"} ?? "else")
        } else {
            elseBlock = postBlock
        }
        
        generator.builder.buildCondBr(condition: try condition.tryBuilding(generator: generator), then: bodyBlock, else: elseBlock)
        
        generator.builder.positionAtEnd(of: bodyBlock)
        try buildChildren(generator: generator)
        generator.builder.buildBr(postBlock)
        
        if let elseBranch = elseBranch {
            generator.builder.positionAtEnd(of: elseBlock)
            guard let elseBranch = elseBranch as? RepresentableInstruction else {
                throw GRPHCompileError(type: .unsupported, message: "Else branch of type \(type(of: elseBranch)) is not supported in IRGen mode")
            }
            try elseBranch.build(generator: generator)
            generator.builder.buildBr(postBlock)
        }
        
        generator.builder.positionAtEnd(of: postBlock)
    }
}
