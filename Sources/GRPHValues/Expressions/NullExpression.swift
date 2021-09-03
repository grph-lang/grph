//
//  NullExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation

public struct NullExpression: Expression {
    public func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        if infer is OptionalType {
            return infer
        }
        return OptionalType(wrapped: SimpleType.mixed)
    }
    
    public var string: String { "null" }
    
    public var needsBrackets: Bool { false }
}
