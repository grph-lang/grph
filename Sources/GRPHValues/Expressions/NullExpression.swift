//
//  NullExpression.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 03/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct NullExpression: Expression {
    
    public init() {}
    
    public func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        if infer is OptionalType {
            return infer
        }
        return OptionalType(wrapped: SimpleType.mixed)
    }
    
    public var string: String { "null" }
    
    public var needsBrackets: Bool { false }
}

public extension NullExpression {
    var astNodeData: String {
        "null literal"
    }
    
    var astChildren: [ASTElement] { [] }
}
