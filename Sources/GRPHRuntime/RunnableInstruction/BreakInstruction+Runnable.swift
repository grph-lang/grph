//
//  BreakInstruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation
import GRPHValues

extension BreakInstruction: RunnableInstruction {
    func run(context: inout RuntimeContext) throws {
        switch type {
        case .break:
            try context.breakBlock(scope: scope)
        case .continue:
            try context.continueBlock(scope: scope)
        case .fall:
            try context.fallFromBlock(scope: scope)
        case .fallthrough:
            try context.fallthroughNextBlock(scope: scope)
        }
    }
}

extension ReturnInstruction: RunnableInstruction {
    func run(context: inout RuntimeContext) throws {
        try context.returnFunction(returnValue: value?.evalIfRunnable(context: context))
    }
}
