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
    public let array: Expression
    public let index: Expression?
    public let removing: Bool
    
    public init(context: CompilingContext, varName: String, index: Expression?, removing: Bool) throws {
        self.array = try GRPHTypes.autobox(context: context, expression: VariableExpression(context: context, name: varName), expected: ArrayType(content: SimpleType.mixed))
        self.index = index == nil ? nil : try GRPHTypes.autobox(context: context, expression: index!, expected: SimpleType.integer)
        self.removing = removing
        guard self.array.getType() is ArrayType else {
            throw GRPHCompileError(type: .invalidArguments, message: "Array expression with non-array variable")
        }
    }
    
    public func getType() -> GRPHType {
        return (self.array.getType() as! ArrayType).content
    }
    
    public var string: String { "\(array.string){\(index?.string ?? "")\(removing ? "-" : "")}" }
    
    public var needsBrackets: Bool { false }
}

public extension ArrayValueExpression {
    var astNodeData: String {
        "access an element of an array \(removing ? " and remove it" : "")"
    }
    
    var astChildren: [ASTElement] {
        [
            ASTElement(name: "array", value: array),
            ASTElement(name: "index", value: index)
        ]
    }
}
