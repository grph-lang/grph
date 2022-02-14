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
    public let type: GRPHType
    
    public init(context: CompilingContext, name: String) throws {
        self.name = name
        guard let v = context.findVariable(named: name) else {
            throw GRPHCompileError(type: .undeclared, message: "Unknown variable '\(name)'")
        }
        self.type = v.type
    }
    
    public func getType() -> GRPHType {
        type
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

public extension VariableExpression {
    var astNodeData: String {
        "retrieve variable \(name)"
    }
    
    var astChildren: [ASTElement] { [] }
}
