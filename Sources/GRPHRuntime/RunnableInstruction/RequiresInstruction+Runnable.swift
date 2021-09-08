//
//  RequiresInstruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 15/07/2020.
//

import Foundation
import GRPHValues

extension RequiresInstruction: RunnableInstruction {
    func run(context: inout RuntimeContext) throws {
        try run(context: context)
    }
}
