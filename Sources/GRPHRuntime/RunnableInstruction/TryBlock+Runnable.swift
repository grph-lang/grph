//
//  TryBlock.swift
//  GRPH Runtime
//
//  Created by Emil Pedersen on 04/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
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
