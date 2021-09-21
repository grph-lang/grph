//
//  VariableExpression.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 02/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct VariableExpression: Expression {
    public let name: String
    
    public init(name: String) {
        self.name = name
    }
    
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
