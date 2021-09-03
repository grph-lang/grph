//
//  NullExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation

struct NullExpression: Expression {
    func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        if infer is OptionalType {
            return infer
        }
        return OptionalType(wrapped: SimpleType.mixed)
    }
    
    var string: String { "null" }
    
    var needsBrackets: Bool { false }
}
