//
//  FuncRefCallExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 26/08/2021.
//

import Foundation

struct FuncRefCallExpression: Expression {
    let varName: String
    let values: [Expression?]
    
    init(ctx: CompilingContext, varName: String, values: [Expression], asInstruction: Bool = false) throws {
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
        
        var ourvalues: [Expression?] = []
        guard asInstruction || !function.returnType.isTheVoid else {
            throw GRPHCompileError(type: .typeMismatch, message: "Void function can't be used as an expression")
        }
        var nextParam = 0
        for param in values {
            guard let par = try function.parameter(index: nextParam, context: ctx, exp: param) else {
                if nextParam >= function.parameters.count && !function.varargs {
                    throw GRPHCompileError(type: .typeMismatch, message: "Unexpected argument '\(param.string)' for out of bounds parameter in funcref call '\(varName)'")
                }
                throw GRPHCompileError(type: .typeMismatch, message: "Unexpected '\(param.string)' of type '\(try param.getType(context: ctx, infer: function.parameter(index: nextParam).type))' in funcref call '\(varName)'")
            }
            nextParam += par.add
            while ourvalues.count < nextParam - 1 {
                ourvalues.append(nil)
            }
            ourvalues.append(try GRPHTypes.autobox(context: ctx, expression: param, expected: par.param.type))
            // at pars[nextParam - 1] aka current param
        }
        while nextParam < function.parameters.count {
            guard function.parameters[nextParam].optional else {
                throw GRPHCompileError(type: .invalidArguments, message: "No argument passed to parameter '\(function.parameters[nextParam].name)' in funcref call '\(varName)'")
            }
            nextParam += 1
        }
        self.values = ourvalues
    }
    
    func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        guard let variable = context.findVariable(named: varName),
              let funcref = variable.type as? FuncRefType else {
            throw GRPHCompileError(type: .undeclared, message: "Unknown funcref '\(varName)'")
        }
        return funcref.returnType
    }
    
    var string: String {
        "\(varName)^[\(FuncRefType(returnType: SimpleType.void, parameterTypes: []).formattedParameterList(values: values.compactMap {$0}))]"
    }
    
    var needsBrackets: Bool { false }
}
