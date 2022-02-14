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
    
    var type: OptionalType
    
    public init(infer: GRPHType) {
        if let infer = infer as? OptionalType {
            type = infer
        } else {
            type = OptionalType(wrapped: SimpleType.mixed)
        }
    }
    
    public func getType() -> GRPHType {
        type
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
