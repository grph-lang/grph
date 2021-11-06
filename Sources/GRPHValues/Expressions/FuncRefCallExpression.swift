//
//  FuncRefCallExpression.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 26/08/2021.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct FuncRefCallExpression: Expression {
    public let varName: String
    public let values: [Expression?]
    
    public init(ctx: CompilingContext, varName: String, values: [Expression], asInstruction: Bool = false) throws {
        self.varName = varName
        
        guard let variable = ctx.findVariable(named: varName) else {
            throw GRPHCompileError(type: .undeclared, message: "Unknown variable '\(varName)'")
        }
        
        let autoboxedType = GRPHTypes.autoboxed(type: variable.type, expected: SimpleType.funcref)
        
        guard let function = autoboxedType as? FuncRefType else {
            if autoboxedType as? SimpleType == SimpleType.funcref {
                throw GRPHCompileError(type: .typeMismatch, message: "Funcref call on non-specialized funcref variable, add return type and parameter types to the variable type, or use reflection")
            }
            throw GRPHCompileError(type: .typeMismatch, message: "Funcref call on variable of type '\(variable.type)' (expected funcref)")
        }
        guard asInstruction || !function.returnType.isTheVoid else {
            throw GRPHCompileError(type: .typeMismatch, message: "Void function can't be used as an expression")
        }
        self.values = try function.populateArgumentList(ctx: ctx, values: values, nameForErrors: "funcref call '\(varName)'")
    }
    
    public func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        guard let variable = context.findVariable(named: varName),
              let funcref = variable.type as? FuncRefType else {
            throw GRPHCompileError(type: .undeclared, message: "Unknown funcref '\(varName)'")
        }
        return funcref.returnType
    }
    
    public var string: String {
        "\(varName)^[\(FuncRefType(returnType: SimpleType.void, parameterTypes: []).formattedParameterList(values: values.compactMap {$0}))]"
    }
    
    public var needsBrackets: Bool { false }
}
