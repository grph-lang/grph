//
//  TryBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation
import GRPHValues

extension TryBlock: RunnableBlockInstruction {
    func canRun(context: BlockRuntimeContext) throws -> Bool { true }
    
    func run(context: inout RuntimeContext) throws {
        do {
            let ctx = createContext(&context)
            try runChildren(context: ctx)
        } catch let e as GRPHRuntimeError {
            if let c = catches[e.type] {
                try c.exceptionCatched(context: &context, exception: e)
            } else if let c = catches[nil] {
                try c.exceptionCatched(context: &context, exception: e)
            } else {
                throw e
            }
        }
    }
}
