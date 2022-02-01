//
//  ArrayValueExpression.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 02/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct ArrayValueExpression: Expression {
    public let varName: String
    public let index: Expression?
    public let removing: Bool
    
    public init(context: CompilingContext, varName: String, index: Expression?, removing: Bool) throws {
        self.varName = varName
        self.index = index == nil ? nil : try GRPHTypes.autobox(context: context, expression: index!, expected: SimpleType.integer)
        self.removing = removing
    }
    
    public func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        guard let v = context.findVariable(named: varName) else {
            throw GRPHCompileError(type: .undeclared, message: "Unknown variable '\(varName)'")
        }
        guard let type = GRPHTypes.autoboxed(type: v.type, expected: ArrayType(content: SimpleType.mixed)) as? ArrayType else {
            throw GRPHCompileError(type: .invalidArguments, message: "Array expression with non-array variable")
        }
        return type.content
    }
    
    public var string: String { "\(varName){\(index?.string ?? "")\(removing ? "-" : "")}" }
    
    public var needsBrackets: Bool { false }
}

public extension ArrayValueExpression {
    var astNodeData: String {
        "access an element of array '\(varName)'\(removing ? " and remove it" : "")"
    }
    
    var astChildren: [ASTElement] {
        [
            ASTElement(name: "index", value: index.map { [$0] } ?? [])
        ]
    }
}
