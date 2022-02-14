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

public final class WhileBlock: BlockInstruction, ElseableBlock {
    public let lineNumber: Int
    public var children: [Instruction] = []
    public var label: String?
    
    public let condition: Expression
    public var elseBranch: ElseLikeBlock?
    
    public init(lineNumber: Int, compiler: GRPHCompilerProtocol, condition: Expression) throws {
        self.lineNumber = lineNumber
        self.condition = try GRPHTypes.autobox(context: compiler.context, expression: condition, expected: SimpleType.boolean)
        createContext(&compiler.context)
        guard self.condition.getType() == SimpleType.boolean else {
            throw GRPHCompileError(type: .typeMismatch, message: "#while needs a boolean, a \(condition.getType()) was given")
        }
    }
    
    public var name: String { "while \(condition.string)" }
    
    public var astNodeData: String {
        "while block"
    }
    
    public var astChildren: [ASTElement] {
        [
            ASTElement(name: "condition", value: [condition]),
            astBlockChildren,
            ASTElement(name: "else", value: elseBranch)
        ]
    }
}
