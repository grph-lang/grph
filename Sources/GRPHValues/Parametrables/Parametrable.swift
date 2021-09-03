//
//  Parametrable.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation

protocol Parametrable {
    var parameters: [Parameter] { get }
    
    var returnType: GRPHType { get }
    
    var varargs: Bool { get }
}

extension Parametrable {
    
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
    
//    func labelled(values: [GRPHValue]) throws -> [GRPHValue?] {
//        guard (values.count & 1) == 0 else {
//            throw GRPHRuntimeError(type: .reflection, message: "Expected pairs of name-values")
//        }
//        var result = [GRPHValue?]()
//        for i in 0..<values.count where (i & 1) == 0 {
//            guard let name = values[i] as? String else {
//                throw GRPHRuntimeError(type: .reflection, message: "Expected a label (string) at position \(i) in varargs")
//            }
//            guard let index = parameters.dropFirst(result.count).firstIndex(where: { $0.name == name }) else {
//                throw GRPHRuntimeError(type: .reflection, message: "No parameter name '\(name)' found")
//            }
//            let param = parameters[index]
//            while result.count < index {
//                guard parameters[result.count].optional else {
//                    throw GRPHRuntimeError(type: .reflection, message: "Parameter '\(parameters[result.count].name)' is not optional")
//                }
//                result.append(nil)
//            }
//            if varargs && index == parameters.count - 1 {
//                let value = try GRPHTypes.autobox(value: values[i + 1], expected: param.type.inArray)
//                guard let arr = value as? GRPHArray,
//                      arr.type.isInstance(of: param.type) else {
//                    throw GRPHRuntimeError(type: .reflection, message: "Expected parameter of type '\(param.type.inArray)' for varargs '\(name)'")
//                }
//                arr.wrapped.forEach { result.append($0) }
//            } else {
//                let value = try GRPHTypes.autobox(value: values[i + 1], expected: param.type)
//                guard GRPHTypes.type(of: value, expected: param.type).isInstance(of: param.type) else {
//                    throw GRPHRuntimeError(type: .reflection, message: "Expected parameter of type '\(param.type)' for '\(name)', found a \(GRPHTypes.type(of: value, expected: param.type))")
//                }
//                result.append(value)
//            }
//        }
//        return result
//    }
}
