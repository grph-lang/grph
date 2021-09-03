//
//  CatchBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation

// Reference type required because it is referenced in the corresponding #try block
class CatchBlock: BlockInstruction {
    let lineNumber: Int
    var children: [Instruction] = []
    var label: String?
    
    let varName: String
    var def: String = ""
    
    init(lineNumber: Int, context: inout CompilingContext, varName: String) throws {
        self.varName = varName
        self.lineNumber = lineNumber
        let ctx = createContext(&context)
        
        guard VariableDeclarationInstruction.varNameRequirement.firstMatch(string: self.varName) != nil else {
            throw GRPHCompileError(type: .parse, message: "Illegal variable name \(self.varName)")
        }
        
        ctx.variables.append(Variable(name: varName, type: SimpleType.string, final: true, compileTime: true))
    }
    
    func addError(type: String) {
        if def.isEmpty {
            def = type
        } else {
            def += " | \(type)"
        }
    }
    
    var name: String { "catch \(varName) : \(def)" }
}
