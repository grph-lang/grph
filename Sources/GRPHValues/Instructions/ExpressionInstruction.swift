//
//  ExpressionInstruction.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 06/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public final class ExpressionInstruction: Instruction {
    public let lineNumber: Int
    public let expression: Expression
    
    public init(lineNumber: Int, expression: Expression) {
        self.lineNumber = lineNumber
        self.expression = expression
    }
    
    public func toString(indent: String) -> String {
        "\(line):\(indent)\(expression)\n"
    }
}
