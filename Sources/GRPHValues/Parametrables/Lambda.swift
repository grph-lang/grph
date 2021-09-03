//
//  Lambda.swift
//  Lambda
//
//  Created by Emil Pedersen on 26/08/2021.
//

import Foundation

public struct Lambda: Parametrable {
    
    public var currentType: FuncRefType
    public var instruction: Instruction // will always be an ExpressionInstruction if returnType ≠ void
    
    public var parameters: [Parameter] { currentType.parameters }
    
    public var returnType: GRPHType { currentType.returnType }
    
    public var varargs: Bool { false }
    
    public var line: Int { instruction.line }
    
}
