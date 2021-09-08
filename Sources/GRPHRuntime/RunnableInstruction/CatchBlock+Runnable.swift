//
//  CatchBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation
import GRPHValues

extension CatchBlock: RunnableBlockInstruction {
    func exceptionCatched(context: inout RuntimeContext, exception: GRPHRuntimeError) throws {
        do {
            let ctx = createContext(&context)
            let v = Variable(name: varName, type: SimpleType.string, content: exception.message, final: true)
            ctx.variables.append(v)
            if context.runtime.debugging {
                printout("[DEBUG VAR \(v.name)=\(v.content!)]")
            }
            try self.runChildren(context: ctx)
        } catch var exception as GRPHRuntimeError {
            exception.stack.append("\tat \(type(of: self)); line \(line)")
            throw exception
        }
    }
    
    func canRun(context: BlockRuntimeContext) throws -> Bool { false }
}
