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
    
    func doRun(context: BlockRuntimeContext) throws
    
    func canRun(context: BlockRuntimeContext) throws -> Bool
}

extension RunnableBlockInstruction {
    @discardableResult func createContext(_ context: inout RuntimeContext) -> BlockRuntimeContext {
        let ctx = BlockRuntimeContext(parent: context, block: self)
        context = ctx
        return ctx
    }
    
    func doRun(context: BlockRuntimeContext) throws {
        context.variables.removeAll()
        try runChildren(context: context)
    }
    
    func runElseBranchIfNeeded(previousBranchContext ctx: BlockRuntimeContext) throws {
        var ogctx = ctx.parent!
        if ctx.canNextRun || ctx.mustNextRun,
           let self = self as? ElseableBlock,
           let elseBranch = self.elseBranch {
            guard let elseBranch = elseBranch as? RunnableBlockInstruction & ElseLikeBlock else {
                throw GRPHRuntimeError(type: .unexpected, message: "Instruction of type \(type(of: elseBranch)) (line \(elseBranch.line)) has no runnable implementation")
            }
            if ctx.mustNextRun {
                try elseBranch.safeRunForce(context: &ogctx)
            } else {
                try elseBranch.safeRun(context: &ogctx)
            }
        }
    }
    
    func run(context: inout RuntimeContext) throws {
        let ctx = createContext(&context)
        if try canRun(context: ctx) {
            try doRun(context: ctx)
        }
        try runElseBranchIfNeeded(previousBranchContext: ctx)
    }
    
    func forceRun(context: inout RuntimeContext) throws where Self: ElseLikeBlock {
        let ctx = createContext(&context)
        try doRun(context: ctx)
    }
    
    func runChildren(context: BlockRuntimeContext) throws {
        context.canNextRun = false
        var i = 0
        while i < children.count && !context.broken && !Thread.current.isCancelled {
            guard let child = children[i] as? RunnableInstruction else {
                throw GRPHRuntimeError(type: .unexpected, message: "Instruction of type \(type(of: children[i])) (line \(children[i].line)) has no runnable implementation")
            }
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
