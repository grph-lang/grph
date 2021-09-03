//
//  IfBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation

struct IfBlock: BlockInstruction {
    let lineNumber: Int
    var children: [Instruction] = []
    var label: String?
    let condition: Expression
    
    init(lineNumber: Int, context: inout CompilingContext, condition: Expression) throws {
        self.lineNumber = lineNumber
        self.condition = try GRPHTypes.autobox(context: context, expression: condition, expected: SimpleType.boolean)
        createContext(&context)
        guard try self.condition.getType(context: context, infer: SimpleType.boolean) == SimpleType.boolean else {
            throw GRPHCompileError(type: .typeMismatch, message: "#if needs a boolean, a \(try condition.getType(context: context, infer: SimpleType.boolean)) was given")
        }
    }
    
    var name: String { "if \(condition.string)" }
}

struct ElseIfBlock: BlockInstruction {
    let lineNumber: Int
    var children: [Instruction] = []
    var label: String?
    let condition: Expression
    
    init(lineNumber: Int, context: inout CompilingContext, condition: Expression) throws {
        self.lineNumber = lineNumber
        self.condition = try GRPHTypes.autobox(context: context, expression: condition, expected: SimpleType.boolean)
        createContext(&context)
        guard try self.condition.getType(context: context, infer: SimpleType.boolean) == SimpleType.boolean else {
            throw GRPHCompileError(type: .typeMismatch, message: "#elseif needs a boolean, a \(try condition.getType(context: context, infer: SimpleType.boolean)) was given")
        }
    }
    
    var name: String { "elseif \(condition.string)" }
}

struct ElseBlock: BlockInstruction {
    let lineNumber: Int
    var children: [Instruction] = []
    var label: String?
    
    init(context: inout CompilingContext, lineNumber: Int) {
        self.lineNumber = lineNumber
        createContext(&context)
    }
    
    var name: String { "else" }
}
