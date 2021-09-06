//
//  ThrowInstruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation

public struct ThrowInstruction: Instruction {
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
}
