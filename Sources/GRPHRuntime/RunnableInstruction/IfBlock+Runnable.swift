//
//  IfBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation
import GRPHValues

extension IfBlock: RunnableBlockInstruction {
    func canRun(context: BlockRuntimeContext) throws -> Bool {
        try condition.evalIfRunnable(context: context) as! Bool
    }
}

extension ElseIfBlock: RunnableBlockInstruction {
    func canRun(context: BlockRuntimeContext) throws -> Bool {
        if let last = context.parent?.previous as? BlockRuntimeContext {
            context.canNextRun = last.canNextRun
            return try context.canNextRun && condition.evalIfRunnable(context: context) as! Bool
        } else {
            throw GRPHRuntimeError(type: .unexpected, message: "#elseif must follow another block instruction")
        }
    }
}

extension ElseBlock: RunnableBlockInstruction {
    func canRun(context: BlockRuntimeContext) throws -> Bool {
        if let last = context.parent?.previous as? BlockRuntimeContext {
            return last.canNextRun
        } else {
            throw GRPHRuntimeError(type: .unexpected, message: "#else must follow another block instruction")
        }
    }
}
