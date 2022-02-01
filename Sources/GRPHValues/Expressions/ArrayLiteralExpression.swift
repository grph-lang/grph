//
//  ArrayLiteralExpression.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 03/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct ArrayLiteralExpression: Expression {
    public let wrapped: GRPHType
    public let values: [Expression]
    
    public init(wrapped: GRPHType, values: [Expression]) {
        self.wrapped = wrapped
        self.values = values
    }
    
    public func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        ArrayType(content: wrapped)
    }
    
    public var string: String {
        var str = "<\(wrapped.string)>{"
        if values.isEmpty {
            return "\(str)}"
        }
        for exp in values {
            if let pos = exp as? ConstantExpression,
               pos.value is Pos {
                str += "[\(exp.string)], " // only location where Pos expressions are bracketized
            } else {
                str += "\(exp.bracketized), "
            }
        }
        return "\(str.dropLast(2))}"
    }
    
    public var needsBrackets: Bool { false }
}

public extension ArrayLiteralExpression {
    var astNodeData: String {
        wrapped.inArray.string
    }
    
    var astChildren: [ASTElement] {
        [
            ASTElement(name: "elements", value: values)
        ]
    }
}
