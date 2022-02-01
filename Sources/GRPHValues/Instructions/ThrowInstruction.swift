//
//  ThrowInstruction.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 05/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public final class ThrowInstruction: Instruction {
    public let lineNumber: Int
    public let type: GRPHRuntimeError.RuntimeExceptionType
    public let message: Expression
    
    public init(lineNumber: Int, type: GRPHRuntimeError.RuntimeExceptionType, message: Expression) {
        self.lineNumber = lineNumber
        self.type = type
        self.message = message
    }
    
    public func toString(indent: String) -> String {
        "\(line):\(indent)#throw \(type.rawValue)Exception(\(message))\n"
    }
    
    public var astNodeData: String {
        "throw exception of type \(type.rawValue)Exception"
    }
    
    public var astChildren: [ASTElement] {
        [ASTElement(name: "message", value: [message])]
    }
}
