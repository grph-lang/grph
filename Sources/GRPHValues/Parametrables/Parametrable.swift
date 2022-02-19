//
//  Parametrable.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 04/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public protocol Parametrable {
    var parameters: [Parameter] { get }
    
    var returnType: GRPHType { get }
    
    var varargs: Bool { get }
}

public extension Parametrable {
    
    func parameter(index: Int) -> Parameter {
        if varargs && index >= parameters.count {
            return parameters[parameters.count - 1]
        }
        return parameters[index]
    }
    
    func parameter(index: Int, expressionType: (GRPHType) throws -> GRPHType) rethrows -> (param: Parameter, add: Int)? {
        var param = index
        while param < maximumParameterCount {
            let curr = parameter(index: param)
            let type = GRPHTypes.autoboxed(type: try expressionType(curr.type), expected: curr.type)
            if type.isInstance(of: curr.type) {
                return (param: curr, add: param - index + 1)
            } else if curr.type.isInstance(of: SimpleType.shape) && type as? SimpleType == SimpleType.shape {
                return (param: curr, add: param - index + 1) // Backwards compatibility
            } else if !curr.optional {
                return nil // missing
            } else if param >= parameters.count - 1 {
                return nil // this was the last, varargs always have the same type (avoid infinite loop)
            }
            param += 1
        }
        return nil
    }
    
    var minimumParameterCount: Int {
        parameters.filter { $0.optional }.count
    }
    
    var maximumParameterCount: Int {
        varargs ? Int.max : parameters.count
    }
    
    func formattedParameterList(values: [Expression]) -> String {
        values.map { $0.bracketized }.joined(separator: " ")
    }
}

extension Parametrable {
    func populateArgumentList<T>(ctx: CompilingContext, values: [T], resolver: (T, GRPHType) throws -> Expression, nameForErrors: @autoclosure () -> String) throws -> [Expression?] {
        var ourvalues: [Expression?] = []
        var nextParam = 0
        
        for paramToResolve in values {
            var param: Expression!
            guard let par = try parameter(index: nextParam, expressionType: { infer in
                param = try resolver(paramToResolve, infer)
                return param.getType()
            })  else {
                throw GRPHCompileError(type: .typeMismatch, message: "Unexpected parameter at position \(nextParam) in \(nameForErrors())")
            }
            nextParam += par.add
            while ourvalues.count < nextParam - 1 {
                ourvalues.append(nil)
            }
            ourvalues.append(try GRPHTypes.autobox(context: ctx, expression: param, expected: par.param.type))
            // at pars[nextParam - 1] aka current param
        }
        while nextParam < parameters.count {
            guard parameters[nextParam].optional else {
                throw GRPHCompileError(type: .invalidArguments, message: "No argument passed to parameter '\(parameters[nextParam].name)' in \(nameForErrors())")
            }
            nextParam += 1
        }
        return ourvalues
    }
}
