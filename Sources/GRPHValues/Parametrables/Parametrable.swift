//
//  Parametrable.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
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
    
    func parameter(index: Int, context: CompilingContext, exp: Expression) throws -> (param: Parameter, add: Int)? {
        try parameter(index: index) { infer in
            try exp.getType(context: context, infer: infer)
        }
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
