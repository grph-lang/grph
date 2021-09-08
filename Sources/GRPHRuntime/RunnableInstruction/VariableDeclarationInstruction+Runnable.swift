//
//  VariableDeclarationInstruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
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
