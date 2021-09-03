//
//  ConstructorExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation

struct ConstructorExpression: Expression {
    let constructor: Constructor
    let values: [Expression?]
    
    init(ctx: CompilingContext, type: GRPHType, values: [Expression]) throws {
        guard let constructor = type.constructor else {
            throw GRPHCompileError(type: .typeMismatch, message: "No constructor found in '\(type)'");
        }
        self.constructor = constructor
        // Java did kinda support multiple constructor but they didn't exist
        var nextParam = 0
        var ourvalues: [Expression?] = []
        for param in values {
            guard let par = try constructor.parameter(index: nextParam, context: ctx, exp: param) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Unexpected '\(param.string)' of type '\(try param.getType(context: ctx, infer: constructor.parameter(index: nextParam).type))' in constructor for '\(type.string)'")
            }
            nextParam += par.add
            while ourvalues.count < nextParam - 1 {
                ourvalues.append(nil)
            }
            ourvalues.append(try GRPHTypes.autobox(context: ctx, expression: param, expected: par.param.type))
            // at pars[nextParam - 1] aka current param
        }
        while nextParam < constructor.parameters.count {
            guard constructor.parameters[nextParam].optional else {
                throw GRPHCompileError(type: .invalidArguments, message: "No argument passed to parameter '\(constructor.parameters[nextParam].name)' in constructor for '\(constructor.name)'")
            }
            nextParam += 1
        }
        self.values = ourvalues
    }
    
    init(ctx: CompilingContext, boxing: Expression, infer: GRPHType) throws {
        self.constructor = try boxing.getType(context: ctx, infer: infer).optional.constructor!
        self.values = [boxing]
    }
    
    func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        constructor.type
    }
    
    var string: String {
        "\(constructor.type.string)(\(constructor.formattedParameterList(values: values.compactMap {$0})))"
    }
    
    var needsBrackets: Bool { false }
}
