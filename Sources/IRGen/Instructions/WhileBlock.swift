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

extension WhileBlock: RepresentableInstruction {
    func build(generator: IRGenerator) throws {
        let condBlock = generator.builder.currentFunction!.appendBasicBlock(named: label.map { "\($0).cond"} ?? "cond")
        let whileBlock = generator.builder.currentFunction!.appendBasicBlock(named: label.map { "\($0).body"} ?? "body")
        let postBlock = generator.builder.currentFunction!.appendBasicBlock(named: label.map { "\($0).post"} ?? "post")
        
        generator.builder.buildBr(condBlock)
        generator.builder.positionAtEnd(of: condBlock)
        
        generator.builder.buildCondBr(condition: try condition.tryBuilding(generator: generator), then: whileBlock, else: postBlock)
        
        generator.builder.positionAtEnd(of: whileBlock)
        try buildChildren(generator: generator)
        generator.builder.buildBr(condBlock)
        generator.builder.positionAtEnd(of: postBlock)
    }
}
