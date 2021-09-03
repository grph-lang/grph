//
//  VariableDeclarationInstruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

struct VariableDeclarationInstruction: Instruction {
    static let varNameRequirement = try! NSRegularExpression(pattern: "^[$A-Za-z_][A-Za-z0-9_]*$")
    
    let global, constant: Bool
    
    let type: GRPHType
    let name: String
    let value: Expression
    
    let lineNumber: Int
    
    init(lineNumber: Int, global: Bool, constant: Bool, type: GRPHType, name: String, value: Expression) {
        self.lineNumber = lineNumber
        self.global = global
        self.constant = constant
        self.type = type
        self.name = name
        self.value = value
    }
    
    init(lineNumber: Int, context: CompilingContext, global: Bool, constant: Bool, typeOrAuto: GRPHType?, name: String, exp: Expression) throws {
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
            guard try type.isInstance(context: context, expression: value) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Incompatible types '\(try value.getType(context: context, infer: type))' and '\(type)' in declaration")
            }
        } else {
            value = exp
            type = try value.getType(context: context, infer: SimpleType.mixed)
        }
        context.addVariable(Variable(name: name, type: type, final: constant, compileTime: true), global: global)
        self.init(lineNumber: lineNumber, global: global, constant: constant, type: type, name: name, value: value)
    }
    
    func toString(indent: String) -> String {
        "\(line):\(indent)\(global ? "global " : "")\(constant ? "final " : "")\(type.string) \(name) = \(value.string)\n"
    }
}
