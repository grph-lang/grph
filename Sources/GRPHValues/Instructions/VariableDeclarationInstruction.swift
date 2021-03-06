//
//  VariableDeclarationInstruction.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 02/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public final class VariableDeclarationInstruction: Instruction {
    public static let varNameRequirement = try! NSRegularExpression(pattern: "^[$A-Za-z_][A-Za-z0-9_]*$")
    
    public let global, constant: Bool
    
    public let type: GRPHType
    public let name: String
    public let value: Expression
    
    public let lineNumber: Int
    
    public init(lineNumber: Int, global: Bool, constant: Bool, type: GRPHType, name: String, value: Expression) {
        self.lineNumber = lineNumber
        self.global = global
        self.constant = constant
        self.type = type
        self.name = name
        self.value = value
    }
    
    public convenience init(lineNumber: Int, context: CompilingContext, global: Bool, constant: Bool, typeOrAuto: GRPHType?, name: String, exp: Expression) throws {
        guard context.findVariableInScope(named: name) == nil else {
            throw GRPHCompileError(type: .redeclaration, message: "Invalid redeclaration of variable '\(name)'")
        }
        guard VariableDeclarationInstruction.varNameRequirement.firstMatch(string: name) != nil else {
            throw GRPHCompileError(type: .parse, message: "Invalid variable name '\(name)'")
        }
        let value: Expression
        let type: GRPHType
        
        if let type0 = typeOrAuto {
            value = try GRPHTypes.autobox(context: context, expression: exp, expected: type0)
            type = type0
            guard type.isInstance(context: context, expression: value) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Incompatible types '\(value.getType())' and '\(type)' in declaration")
            }
        } else {
            value = exp
            type = value.getType()
        }
        context.addVariable(Variable(name: name, type: type, final: constant, compileTime: true), global: global)
        self.init(lineNumber: lineNumber, global: global, constant: constant, type: type, name: name, value: value)
    }
    
    public func toString(indent: String) -> String {
        "\(line):\(indent)\(global ? "global " : "")\(constant ? "final " : "")\(type.string) \(name) = \(value.string)\n"
    }
    
    public var astNodeData: String {
        "declare \(global ? "global " : "")\(constant ? "constant" : "variable") \(name) of type \(type)"
    }
    
    public var astChildren: [ASTElement] {
        [
            ASTElement(name: "initializer", value: [value])
        ]
    }
}
