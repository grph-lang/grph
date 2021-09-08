//
//  WhileBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation
import GRPHValues

extension WhileBlock: RunnableBlockInstruction {
    func canRun(context: BlockRuntimeContext) throws -> Bool {
        try condition.evalIfRunnable(context: context) as! Bool
    }
    
    func run(context: inout RuntimeContext) throws {
        let ctx = createContext(&context)
        while try mustRun(context: ctx) || (!ctx.broken && canRun(context: ctx)) {
            ctx.variables.removeAll()
            try runChildren(context: ctx)
        }
    }
}
