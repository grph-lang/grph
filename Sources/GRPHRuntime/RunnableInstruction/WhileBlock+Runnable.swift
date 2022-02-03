//
//  WhileBlock.swift
//  GRPH Runtime
//
//  Created by Emil Pedersen on 04/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues

extension WhileBlock: RunnableBlockInstruction {
    func canRun(context: BlockRuntimeContext) throws -> Bool {
        try condition.evalIfRunnable(context: context) as! Bool
    }
    
    func run(context: inout RuntimeContext) throws {
        let ctx = createContext(&context)
        while try !ctx.broken && canRun(context: ctx) {
            ctx.variables.removeAll()
            try runChildren(context: ctx)
        }
        try runElseBranchIfNeeded(previousBranchContext: ctx)
    }
}
