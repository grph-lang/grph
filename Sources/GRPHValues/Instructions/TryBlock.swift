//
//  TryBlock.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 04/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public final class TryBlock: BlockInstruction {
    public let lineNumber: Int
    public var children: [Instruction] = []
    public var label: String?
    
    public var catches: [GRPHRuntimeError.RuntimeExceptionType?: CatchBlock] = [:]
    
    public init(compiler: GRPHCompilerProtocol, lineNumber: Int) {
        self.lineNumber = lineNumber
        createContext(&compiler.context)
    }
    
    public var name: String { "try" }
    
    public func toString(indent: String) -> String {
        var builder = defaultStringForBlock(indent: indent)
        for block in Set(catches.values) {
            builder += block.toString(indent: indent)
        }
        return builder
    }
    
    public var astNodeData: String {
        "try block"
    }
    
    public var astChildren: [ASTElement] {
        [
            astBlockChildren,
            ASTElement(name: "catches", value: Array(Set(catches.values)))
        ]
    }
}
