//
//  Parametrable.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation
import GRPHValues

extension Parametrable {
    func labelled(values: [GRPHValue]) throws -> [GRPHValue?] {
        guard (values.count & 1) == 0 else {
            throw GRPHRuntimeError(type: .reflection, message: "Expected pairs of name-values")
        }
        var result = [GRPHValue?]()
        for i in 0..<values.count where (i & 1) == 0 {
            guard let name = values[i] as? String else {
                throw GRPHRuntimeError(type: .reflection, message: "Expected a label (string) at position \(i) in varargs")
            }
            guard let index = parameters.dropFirst(result.count).firstIndex(where: { $0.name == name }) else {
                throw GRPHRuntimeError(type: .reflection, message: "No parameter name '\(name)' found")
            }
            let param = parameters[index]
            while result.count < index {
                guard parameters[result.count].optional else {
                    throw GRPHRuntimeError(type: .reflection, message: "Parameter '\(parameters[result.count].name)' is not optional")
                }
                result.append(nil)
            }
            if varargs && index == parameters.count - 1 {
                let value = try GRPHTypes.autobox(value: values[i + 1], expected: param.type.inArray)
                guard let arr = value as? GRPHArray,
                      arr.type.isInstance(of: param.type) else {
                    throw GRPHRuntimeError(type: .reflection, message: "Expected parameter of type '\(param.type.inArray)' for varargs '\(name)'")
                }
                arr.wrapped.forEach { result.append($0) }
            } else {
                let value = try GRPHTypes.autobox(value: values[i + 1], expected: param.type)
                guard GRPHTypes.type(of: value, expected: param.type).isInstance(of: param.type) else {
                    throw GRPHRuntimeError(type: .reflection, message: "Expected parameter of type '\(param.type)' for '\(name)', found a \(GRPHTypes.type(of: value, expected: param.type))")
                }
                result.append(value)
            }
        }
        return result
    }
}
