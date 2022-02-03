//
//  IfBlock.swift
//  GRPH Runtime
//
//  Created by Emil Pedersen on 03/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
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
        try condition.evalIfRunnable(context: context) as! Bool
    }
}

extension ElseBlock: RunnableBlockInstruction {
    func canRun(context: BlockRuntimeContext) throws -> Bool {
        true
    }
}
