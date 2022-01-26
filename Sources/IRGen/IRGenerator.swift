//
//  IRGenerator.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 26/01/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

public class IRGenerator {
    let builder: IRBuilder
    
    public var module: Module { builder.module }
    
    public init(filename: String) {
        builder = IRBuilder(module: Module(name: filename))
    }
    
    public func build(from: [GRPHValues.Instruction]) throws {
        let main = builder.addFunction("main", type: FunctionType([], IntType.int32))
        builder.positionAtEnd(of: main.appendBasicBlock(named: "entry"))
        
        builder.buildRet(IntType.int32.constant(0))
    }
}
