//
//  LambdaExpression.swift
//  LambdaExpression
//
//  Created by Emil Pedersen on 26/08/2021.
//

import Foundation

struct LambdaExpression: Expression {
    let lambda: Lambda
    let capturedVarNames: [String]
    
    func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        lambda.currentType
    }
    
    var string: String {
        let instr = lambda.instruction.toString(indent: "").dropLast()
        let colon = instr.firstIndex(of: ":")!
        return "^[\(instr[instr.index(after: colon)...])]"
    }
    
    var needsBrackets: Bool { false }
}
