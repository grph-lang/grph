//
//  TryBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation

struct TryBlock: BlockInstruction {
    let lineNumber: Int
    var children: [Instruction] = []
    var label: String?
    var catches: [GRPHRuntimeError.RuntimeExceptionType?: CatchBlock] = [:]
    
    init(context: inout CompilingContext, lineNumber: Int) {
        self.lineNumber = lineNumber
        createContext(&context)
    }
    
    var name: String { "try" }
}
