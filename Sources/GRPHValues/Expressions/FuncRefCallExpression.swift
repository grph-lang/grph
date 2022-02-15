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
    public let exp: Expression
    public let values: [Expression?]
    
    public init<T>(ctx: CompilingContext, varName: String, values: [T], resolver: (T, GRPHType) throws -> Expression, asInstruction: Bool = false) throws {
        self.exp = try GRPHTypes.autobox(context: ctx, expression: VariableExpression(context: ctx, name: varName), expected: SimpleType.funcref)
        let autoboxedType = self.exp.getType()
        
        guard let function = autoboxedType as? FuncRefType else {
            if autoboxedType as? SimpleType == SimpleType.funcref {
                throw GRPHCompileError(type: .typeMismatch, message: "Funcref call on non-specialized funcref variable, add return type and parameter types to the variable type, or use reflection")
            }
            throw GRPHCompileError(type: .typeMismatch, message: "Funcref call on variable of type '\(autoboxedType)' (expected funcref)")
        }
        guard asInstruction || !function.returnType.isTheVoid else {
            throw GRPHCompileError(type: .typeMismatch, message: "Void function can't be used as an expression")
        }
        self.values = try function.populateArgumentList(ctx: ctx, values: values, resolver: resolver, nameForErrors: "funcref call '\(varName)'")
    }
    
    public func getType() -> GRPHType {
        return (exp.getType() as! FuncRefType).returnType
    }
    
    public var string: String {
        "\(exp.string)^[\(FuncRefType(returnType: SimpleType.void, parameterTypes: []).formattedParameterList(values: values.compactMap {$0}))]"
    }
    
    public var needsBrackets: Bool { false }
}

public extension FuncRefCallExpression {
    var astNodeData: String {
        "invocation of a funcref"
    }
    
    var astChildren: [ASTElement] {
        [
            ASTElement(name: "funcref", value: exp),
            ASTElement(name: "arguments", value: values.compactMap({ $0 }))
        ]
    }
}
