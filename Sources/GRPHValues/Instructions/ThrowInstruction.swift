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
    
    public func toString(indent: String) -> String {
        "\(line):\(indent)#throw \(type.rawValue)Exception(\(message))\n"
    }
}
