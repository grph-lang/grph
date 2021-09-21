//
//  BlockInstruction.swift
//  GRPH Runtime
//
//  Created by Emil Pedersen on 02/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues

/// The #block instruction, but also the base class for all other blocks
protocol RunnableBlockInstruction: RunnableInstruction, BlockInstruction {
    @discardableResult func createContext(_ context: inout RuntimeContext) -> BlockRuntimeContext
    
    func run(context: inout RuntimeContext) throws
    
    func mustRun(context: BlockRuntimeContext) -> Bool
    
    func canRun(context: BlockRuntimeContext) throws -> Bool
}

extension RunnableBlockInstruction {
    @discardableResult func createContext(_ context: inout RuntimeContext) -> BlockRuntimeContext {
        let ctx = BlockRuntimeContext(parent: context, block: self)
        context = ctx
        return ctx
    }
    
    func run(context: inout RuntimeContext) throws {
        let ctx = createContext(&context)
        if try mustRun(context: ctx) || canRun(context: ctx) {
            ctx.variables.removeAll()
            try runChildren(context: ctx)
        }
    }
    
    func mustRun(context: BlockRuntimeContext) -> Bool {
        if let last = context.parent?.previous as? BlockRuntimeContext,
           last.mustNextRun {
            last.mustNextRun = false
            return true
        }
        return false
    }
    
    func runChildren(context: BlockRuntimeContext) throws {
        context.canNextRun = false
        var last: RuntimeContext?
        var i = 0
        while i < children.count && !context.broken && !Thread.current.isCancelled {
            guard let child = children[i] as? RunnableInstruction else {
                throw GRPHRuntimeError(type: .unexpected, message: "Instruction of type \(type(of: children[i])) (line \(children[i].line)) has no runnable implementation")
            }
            context.previous = last
            let runtime = context.runtime
            if runtime.debugging {
                printout("[DEBUG LOC \(child.line)]")
            }
            if runtime.image.destroyed {
                throw GRPHExecutionTerminated()
            }
            if runtime.debugStep > 0 {
                _ = runtime.debugSemaphore.wait(timeout: .now() + runtime.debugStep)
            }
            var inner: RuntimeContext = context
            try child.safeRun(context: &inner)
            if inner !== context {
                last = inner
            } else {
                last = nil
            }
            i += 1
        }
        if context.continued {
            context.broken = false
            context.continued = false
        }
    }
}

extension SimpleBlockInstruction: RunnableBlockInstruction {
    func canRun(context: BlockRuntimeContext) throws -> Bool { true }
}
