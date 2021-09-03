//
//  FunctionReferenceExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 25/08/2021.
//

import Foundation

struct FunctionReferenceExpression: Expression {
    var function: Function
    var argumentGrid: [Bool]
    var inferredType: FuncRefType
    
    init(function: Function, infer: GRPHType?) throws {
        self.function = function
        if let infer = infer as? FuncRefType {
            // type check return type
            guard function.returnType.isInstance(of: infer.returnType) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Function with return type '\(infer.returnType.string)' was expected; the return type of '\(function.fullyQualifiedName)' is '\(function.returnType)'")
            }
            
            // type check params
            var nextParam = 0
            var grid: [Bool] = []
            for param in infer.parameterTypes {
                guard let par = function.parameter(index: nextParam, expressionType: { _ in param }) else {
                    if nextParam >= function.parameters.count && !function.varargs {
                        throw GRPHCompileError(type: .typeMismatch, message: "Unexpected argument type '\(param.string)' for out of bounds parameter in funcref to '\(function.name)'")
                    }
                    throw GRPHCompileError(type: .typeMismatch, message: "Unexpected argument type '\(param.string)' for parameter '\(function.parameter(index: nextParam).name)' in funcref to '\(function.name)'")
                }
                nextParam += par.add
                while grid.count < nextParam - 1 {
                    grid.append(false)
                }
                grid.append(true)
            }
            self.argumentGrid = grid
            self.inferredType = infer
        } else {
            // use its signature
            if function.varargs {
                throw GRPHCompileError(type: .typeMismatch, message: "Funcref to function with varargs requires an explicit type, try inferring it with the 'as' operator")
            }
            // we include optional parameters. this choice is arbitrary. if there are optional arguments, you should always specify an explicit type
            // not inferring the type of a funcref to a function with optional arguments should be a warning
            self.argumentGrid = [Bool](repeating: true, count: function.parameters.count)
            self.inferredType = FuncRefType(returnType: function.returnType, parameterTypes: function.parameters.map { $0.type })
        }
    }
    
    func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        inferredType
    }
    
    var string: String { "^\(function.fullyQualifiedName)" }
    
    var needsBrackets: Bool { false }
}
