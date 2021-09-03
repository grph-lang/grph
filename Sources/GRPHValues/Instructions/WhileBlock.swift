//
//  WhileBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation

struct WhileBlock: BlockInstruction {
    let lineNumber: Int
    var children: [Instruction] = []
    var label: String?
    let condition: Expression
    
    init(lineNumber: Int, context: inout CompilingContext, condition: Expression) throws {
        self.lineNumber = lineNumber
        self.condition = try GRPHTypes.autobox(context: context, expression: condition, expected: SimpleType.boolean)
        createContext(&context)
        guard try self.condition.getType(context: context, infer: SimpleType.boolean) == SimpleType.boolean else {
            throw GRPHCompileError(type: .typeMismatch, message: "#while needs a boolean, a \(try condition.getType(context: context, infer: SimpleType.boolean)) was given")
        }
    }
    
    var name: String { "while \(condition.string)" }
}
