//
//  ForEachBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation

struct ForEachBlock: BlockInstruction {
    let lineNumber: Int
    var children: [Instruction] = []
    var label: String?
    
    let varName: String
    let array: Expression
    let inOut: Bool
    
    init(lineNumber: Int, context: inout CompilingContext, varName: String, array: Expression) throws {
        self.inOut = varName.hasPrefix("&") // new in Swift Edition
        self.varName = inOut ? String(varName.dropFirst()) : varName
        self.array = try GRPHTypes.autobox(context: context, expression: array, expected: SimpleType.mixed.inArray)
        self.lineNumber = lineNumber
        let ctx = createContext(&context)
        
        let type = try array.getType(context: context, infer: SimpleType.mixed.inArray)
        
        guard let arrtype = type as? ArrayType else {
            throw GRPHCompileError(type: .typeMismatch, message: "#foreach needs an array, a \(type) was given")
        }
        
        guard VariableDeclarationInstruction.varNameRequirement.firstMatch(string: self.varName) != nil else {
            throw GRPHCompileError(type: .parse, message: "Illegal variable name \(self.varName)")
        }
        ctx.variables.append(Variable(name: self.varName, type: arrtype.content, final: !inOut, compileTime: true))
    }
    
    var name: String { "foreach \(inOut ? "&" : "")\(varName) : \(array.string)" }
}
