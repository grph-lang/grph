//
//  LambdaExpression.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 26/08/2021.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct LambdaExpression: Expression {
    public let lambda: Lambda
    public let capturedVarNames: [String]
    
    public init(lambda: Lambda, capturedVarNames: [String]) {
        self.lambda = lambda
        self.capturedVarNames = capturedVarNames
    }
    
    public func getType() -> GRPHType {
        lambda.currentType
    }
    
    public var string: String {
        let instr = lambda.instruction.toString(indent: "").dropLast()
        let colon = instr.firstIndex(of: ":")!
        return "^[\(instr[instr.index(after: colon)...])]"
    }
    
    public var needsBrackets: Bool { false }
}

public extension LambdaExpression {
    var astNodeData: String {
        "lambda of type \(lambda.currentType) (capturing \(capturedVarNames.joined(separator: ", ")))"
    }
    
    var astChildren: [ASTElement] {
        [
            // TODO: ASTElement(name: "value", value: [lambda.instruction])
        ]
    }
}
