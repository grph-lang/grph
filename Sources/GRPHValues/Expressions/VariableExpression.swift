//
//  VariableExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

public struct VariableExpression: Expression {
    public let name: String
    
    public func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        if let v = context.findVariable(named: name) {
            return v.type
        }
        throw GRPHCompileError(type: .undeclared, message: "Unknown variable '\(name)'")
    }
    
    public var string: String { name }
    
    public var needsBrackets: Bool { false }
}

extension VariableExpression: AssignableExpression {
    public func checkCanAssign(context: CompilingContext) throws {
        guard let v = context.findVariable(named: name),
              !v.final else {
            throw GRPHCompileError(type: .typeMismatch, message: "Cannot assign to final variable '\(name)'")
        }
    }
}
