//
//  Instruction.swift
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
