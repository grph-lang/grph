//
//  MethodExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 13/07/2020.
//

import Foundation

public struct MethodExpression: Expression {
    public let method: Method
    public let on: Expression
    public let values: [Expression?]
    
    public init(ctx: CompilingContext, method: Method, on: Expression, values: [Expression], asInstruction: Bool = false) throws {
        var nextParam = 0
        self.method = method
        self.on = on
        var ourvalues: [Expression?] = []
        guard asInstruction || !method.returnType.isTheVoid else {
            throw GRPHCompileError(type: .typeMismatch, message: "Void function can't be used as an expression")
        }
        for param in values {
            guard let par = try method.parameter(index: nextParam, context: ctx, exp: param) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Unexpected '\(param.string)' of type '\(try param.getType(context: ctx, infer: SimpleType.mixed))' in method '\(method.inType)>\(method.name)'")
            }
            nextParam += par.add
            while ourvalues.count < nextParam - 1 {
                ourvalues.append(nil)
            }
            ourvalues.append(try GRPHTypes.autobox(context: ctx, expression: param, expected: par.param.type))
            // at pars[nextParam - 1] aka current param
        }
        while nextParam < method.parameters.count {
            guard method.parameters[nextParam].optional else {
                throw GRPHCompileError(type: .invalidArguments, message: "No argument passed to parameter '\(method.parameters[nextParam].name)' in method '\(method.name)'")
            }
            nextParam += 1
        }
        self.values = ourvalues
    }
    
    public func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        return method.returnType
    }
    
    public var fullyQualified: String {
        method.fullyQualifiedName
    }
    
    public var string: String {
        "\(on.bracketized).\(fullyQualified)[\(method.formattedParameterList(values: values.compactMap {$0}))]"
    }
    
    public var needsBrackets: Bool { false }
}
