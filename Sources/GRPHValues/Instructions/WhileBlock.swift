//
//  WhileBlock.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 04/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public final class WhileBlock: BlockInstruction {
    public let lineNumber: Int
    public var children: [Instruction] = []
    public var label: String?
    public let condition: Expression
    
    public init(lineNumber: Int, compiler: GRPHCompilerProtocol, condition: Expression) throws {
        self.lineNumber = lineNumber
        self.condition = try GRPHTypes.autobox(context: compiler.context, expression: condition, expected: SimpleType.boolean)
        createContext(&compiler.context)
        guard try self.condition.getType(context: compiler.context, infer: SimpleType.boolean) == SimpleType.boolean else {
            throw GRPHCompileError(type: .typeMismatch, message: "#while needs a boolean, a \(try condition.getType(context: compiler.context, infer: SimpleType.boolean)) was given")
        }
    }
    
    public var name: String { "while \(condition.string)" }
}
