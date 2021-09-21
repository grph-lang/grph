//
//  Lambda.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 26/08/2021.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct Lambda: Parametrable {
    public var currentType: FuncRefType
    public var instruction: Instruction // will always be an ExpressionInstruction if returnType ≠ void
    
    public init(currentType: FuncRefType, instruction: Instruction) {
        self.currentType = currentType
        self.instruction = instruction
    }
    
    public var parameters: [Parameter] { currentType.parameters }
    
    public var returnType: GRPHType { currentType.returnType }
    
    public var varargs: Bool { false }
    
    public var line: Int { instruction.line }
    
}
