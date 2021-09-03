//
//  LambdaExpression.swift
//  LambdaExpression
//
//  Created by Emil Pedersen on 26/08/2021.
//

import Foundation

public struct LambdaExpression: Expression {
    public let lambda: Lambda
    public let capturedVarNames: [String]
    
    public func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        lambda.currentType
    }
    
    public var string: String {
        let instr = lambda.instruction.toString(indent: "").dropLast()
        let colon = instr.firstIndex(of: ":")!
        return "^[\(instr[instr.index(after: colon)...])]"
    }
    
    public var needsBrackets: Bool { false }
}
