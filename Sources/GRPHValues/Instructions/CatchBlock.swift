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

public final class CatchBlock: BlockInstruction {
    public let lineNumber: Int
    public var children: [Instruction] = []
    public var label: String?
    
    public let varName: String
    public var def: String = ""
    
    public init(lineNumber: Int, compiler: GRPHCompilerProtocol, varName: String) throws {
        self.varName = varName
        self.lineNumber = lineNumber
        let ctx = createContext(&compiler.context)
        
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
    
    public var astNodeData: String {
        "catch exceptions of type \(def) into variable \(varName)"
    }
    
    public var astChildren: [ASTElement] {
        [astBlockChildren]
    }
}

extension CatchBlock: Hashable {
    public static func == (lhs: CatchBlock, rhs: CatchBlock) -> Bool {
        lhs === rhs
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
