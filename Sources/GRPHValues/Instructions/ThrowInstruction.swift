//
//  ThrowInstruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation

struct ThrowInstruction: Instruction {
    let lineNumber: Int
    let type: GRPHRuntimeError.RuntimeExceptionType
    let message: Expression
    
    func toString(indent: String) -> String {
        "\(line):\(indent)#throw \(type.rawValue)Exception(\(message))\n"
    }
}
