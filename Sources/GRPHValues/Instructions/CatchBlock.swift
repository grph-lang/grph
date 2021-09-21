//
//  CatchBlock.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 04/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

// Reference type required because it is referenced in the corresponding #try block
public class CatchBlock: BlockInstruction {
    public let lineNumber: Int
    public var children: [Instruction] = []
    public var label: String?
    
    public let varName: String
    public var def: String = ""
    
    public init(lineNumber: Int, context: inout CompilingContext, varName: String) throws {
        self.varName = varName
        self.lineNumber = lineNumber
        let ctx = createContext(&context)
        
        guard VariableDeclarationInstruction.varNameRequirement.firstMatch(string: self.varName) != nil else {
            throw GRPHCompileError(type: .parse, message: "Illegal variable name \(self.varName)")
        }
        
        ctx.variables.append(Variable(name: varName, type: SimpleType.string, final: true, compileTime: true))
    }
    
    public func addError(type: String) {
        if def.isEmpty {
            def = type
        } else {
            def += " | \(type)"
        }
    }
    
    public var name: String { "catch \(varName) : \(def)" }
}
