//
//  VariableDeclarationInstruction.swift
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

extension VariableDeclarationInstruction: RunnableInstruction {
    func run(context: inout RuntimeContext) throws {
        let content = try value.evalIfRunnable(context: context)
        let v = Variable(name: name, type: type, content: content, final: constant)
        context.addVariable(v, global: global)
        if context.runtime.debugging {
            printout("[DEBUG VAR \(v.name)=\(v.content ?? "<@#no content#>")]")
        }
    }
}
