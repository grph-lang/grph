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

extension IfBlock: RepresentableInstruction {
    func build(generator: IRGenerator) throws {
        let bodyBlock = generator.builder.currentFunction!.appendBasicBlock(named: label ?? "if")
        let postBlock = generator.builder.currentFunction!.appendBasicBlock(named: label.map { "\($0).post"} ?? "")
        
        generator.builder.buildCondBr(condition: try condition.tryBuilding(generator: generator), then: bodyBlock, else: postBlock)
        
        generator.builder.positionAtEnd(of: bodyBlock)
        try buildChildren(generator: generator)
        generator.builder.buildBr(postBlock)
        generator.builder.positionAtEnd(of: postBlock)
    }
}
