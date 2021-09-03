//
//  Lambda.swift
//  Lambda
//
//  Created by Emil Pedersen on 26/08/2021.
//

import Foundation

struct Lambda: Parametrable {
    
    var currentType: FuncRefType
    var instruction: Instruction // will always be an ExpressionInstruction if returnType ≠ void
    
    var parameters: [Parameter] { currentType.parameters }
    
    var returnType: GRPHType { currentType.returnType }
    
    var varargs: Bool { false }
    
    var line: Int { instruction.line }
    
}
