//
//  FunctionExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 06/07/2020.
//

import Foundation

struct FunctionExpression: Expression {
    let function: Function
    let values: [Expression?]
    
    init(ctx: CompilingContext, function: Function, values: [Expression], asInstruction: Bool = false) throws {
        self.function = function
        var ourvalues: [Expression?] = []
        guard asInstruction || !function.returnType.isTheVoid else {
            throw GRPHCompileError(type: .typeMismatch, message: "Void function can't be used as an expression")
        }
        var nextParam = 0
        for param in values {
            guard let par = try function.parameter(index: nextParam, context: ctx, exp: param) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Unexpected '\(param.string)' of type '\(try param.getType(context: ctx, infer: function.parameter(index: nextParam).type))' in function '\(function.name)'")
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
                throw GRPHCompileError(type: .invalidArguments, message: "No argument passed to parameter '\(function.parameters[nextParam].name)' in function '\(function.name)'")
            }
            nextParam += 1
        }
        self.values = ourvalues
    }
    
    func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        return function.returnType
    }
    
    var string: String {
        "\(function.fullyQualifiedName)[\(function.formattedParameterList(values: values.compactMap {$0}))]"
    }
    
    var needsBrackets: Bool { false }
}
