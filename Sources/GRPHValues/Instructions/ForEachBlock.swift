//
//  ForEachBlock.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 04/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public final class ForEachBlock: BlockInstruction, ElseableBlock {
    public let lineNumber: Int
    public var children: [Instruction] = []
    public var label: String?
    
    public let varName: String
    public let array: Expression
    public let inOut: Bool
    
    public var elseBranch: ElseLikeBlock?
    
    public init(lineNumber: Int, compiler: GRPHCompilerProtocol, inOut: Bool, varName: String, array: Expression) throws {
        self.varName = varName
        self.inOut = inOut
        self.array = try GRPHTypes.autobox(context: compiler.context, expression: array, expected: SimpleType.mixed.inArray)
        self.lineNumber = lineNumber
        let ctx = createContext(&compiler.context)
        
        let type = self.array.getType()
        
        guard let arrtype = type as? ArrayType else {
            throw GRPHCompileError(type: .typeMismatch, message: "#foreach needs an array, a \(type) was given")
        }
        ctx.variables.append(Variable(name: self.varName, type: arrtype.content, final: !inOut, compileTime: true))
    }
    
    public convenience init(lineNumber: Int, compiler: GRPHCompilerProtocol, varName: String, array: Expression) throws {
        let inOut = varName.hasPrefix("&") // new in Swift Edition
        let name = inOut ? String(varName.dropFirst()) : varName
        
        guard VariableDeclarationInstruction.varNameRequirement.firstMatch(string: name) != nil else {
            throw GRPHCompileError(type: .parse, message: "Illegal variable name \(name)")
        }
        
        try self.init(lineNumber: lineNumber, compiler: compiler, inOut: inOut, varName: name, array: array)
    }
    
    public var name: String { "foreach \(inOut ? "&" : "")\(varName) : \(array.string)" }
    
    public var astNodeData: String {
        "iterate on array, storing the element in variable \(varName)\(inOut ? " as inout" : "")"
    }
    
    public var astChildren: [ASTElement] {
        [
            ASTElement(name: "array", value: [array]),
            astBlockChildren,
            ASTElement(name: "else", value: elseBranch)
        ]
    }
}
