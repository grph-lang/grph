//
//  ArrayLiteralExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation

struct ArrayLiteralExpression: Expression {
    let wrapped: GRPHType
    let values: [Expression]
    
    func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        ArrayType(content: wrapped)
    }
    
    var string: String {
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
    
    var needsBrackets: Bool { false }
}
