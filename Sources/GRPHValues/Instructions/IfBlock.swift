//
//  IfBlock.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 03/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct IfBlock: BlockInstruction {
    public let lineNumber: Int
    public var children: [Instruction] = []
    public var label: String?
    public let condition: Expression
    
    public init(lineNumber: Int, compiler: GRPHCompilerProtocol, condition: Expression) throws {
        self.lineNumber = lineNumber
        self.condition = try GRPHTypes.autobox(context: compiler.context, expression: condition, expected: SimpleType.boolean)
        createContext(&compiler.context)
        guard try self.condition.getType(context: compiler.context, infer: SimpleType.boolean) == SimpleType.boolean else {
            throw GRPHCompileError(type: .typeMismatch, message: "#if needs a boolean, a \(try condition.getType(context: compiler.context, infer: SimpleType.boolean)) was given")
        }
    }
    
    public var name: String { "if \(condition.string)" }
}

public struct ElseIfBlock: BlockInstruction {
    public let lineNumber: Int
    public var children: [Instruction] = []
    public var label: String?
    public let condition: Expression
    
    public init(lineNumber: Int, compiler: GRPHCompilerProtocol, condition: Expression) throws {
        self.lineNumber = lineNumber
        self.condition = try GRPHTypes.autobox(context: compiler.context, expression: condition, expected: SimpleType.boolean)
        createContext(&compiler.context)
        guard try self.condition.getType(context: compiler.context, infer: SimpleType.boolean) == SimpleType.boolean else {
            throw GRPHCompileError(type: .typeMismatch, message: "#elseif needs a boolean, a \(try condition.getType(context: compiler.context, infer: SimpleType.boolean)) was given")
        }
    }
    
    public var name: String { "elseif \(condition.string)" }
}

public struct ElseBlock: BlockInstruction {
    public let lineNumber: Int
    public var children: [Instruction] = []
    public var label: String?
    
    public init(compiler: GRPHCompilerProtocol, lineNumber: Int) {
        self.lineNumber = lineNumber
        createContext(&compiler.context)
    }
    
    public var name: String { "else" }
}
