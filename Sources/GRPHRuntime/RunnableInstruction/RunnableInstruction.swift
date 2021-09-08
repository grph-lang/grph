//
//  Instruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation
import GRPHValues

protocol RunnableInstruction: Instruction {
    func run(context: inout RuntimeContext) throws
}

extension RunnableInstruction {
    func safeRun(context: inout RuntimeContext) throws {
        do {
            try self.run(context: &context)
        } catch var exception as GRPHRuntimeError {
            exception.stack.append("\tat \(type(of: self)); line \(line)")
            throw exception
        }
    }
}
