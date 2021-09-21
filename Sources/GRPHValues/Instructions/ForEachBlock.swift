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

public struct ForEachBlock: BlockInstruction {
    public let lineNumber: Int
    public var children: [Instruction] = []
    public var label: String?
    
    public let varName: String
    public let array: Expression
    public let inOut: Bool
    
    public init(lineNumber: Int, context: inout CompilingContext, inOut: Bool, varName: String, array: Expression) throws {
        self.varName = varName
        self.inOut = inOut
        self.array = try GRPHTypes.autobox(context: context, expression: array, expected: SimpleType.mixed.inArray)
        self.lineNumber = lineNumber
        let ctx = createContext(&context)
        
        let type = try self.array.getType(context: context, infer: SimpleType.mixed.inArray)
        
        guard let arrtype = type as? ArrayType else {
            throw GRPHCompileError(type: .typeMismatch, message: "#foreach needs an array, a \(type) was given")
        }
        ctx.variables.append(Variable(name: self.varName, type: arrtype.content, final: !inOut, compileTime: true))
    }
    
    public init(lineNumber: Int, context: inout CompilingContext, varName: String, array: Expression) throws {
        let inOut = varName.hasPrefix("&") // new in Swift Edition
        let name = inOut ? String(varName.dropFirst()) : varName
        
        guard VariableDeclarationInstruction.varNameRequirement.firstMatch(string: name) != nil else {
            throw GRPHCompileError(type: .parse, message: "Illegal variable name \(name)")
        }
        
        try self.init(lineNumber: lineNumber, context: &context, inOut: inOut, varName: name, array: array)
    }
    
    public var name: String { "foreach \(inOut ? "&" : "")\(varName) : \(array.string)" }
}
