//
//  ExpressionInstruction.swift
//  GRPH Runtime
//
//  Created by Emil Pedersen on 06/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues

extension ExpressionInstruction: RunnableInstruction {
    func run(context: inout RuntimeContext) throws {
        _ = try expression.evalIfRunnable(context: context)
    }
}
