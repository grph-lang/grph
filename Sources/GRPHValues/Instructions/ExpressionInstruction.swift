//
//  ExpressionInstruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 06/07/2020.
//

import Foundation

public struct ExpressionInstruction: Instruction {
    public let lineNumber: Int
    public let expression: Expression
    
    public func toString(indent: String) -> String {
        "\(line):\(indent)\(expression)\n"
    }
}
