//
//  LambdaExpression.swift
//  LambdaExpression
//
//  Created by Emil Pedersen on 26/08/2021.
//

import Foundation
import GRPHValues

extension LambdaExpression: RunnableExpression {
    func eval(context: RuntimeContext) throws -> GRPHValue {
        FuncRef(currentType: lambda.currentType, storage: .lambda(lambda, capture: try capturedVarNames.map { capture in
            if let variable = context.findVariable(named: capture) {
                return variable
            }
            throw GRPHRuntimeError(type: .unexpected, message: "Expected captured variable '\(capture)' to exist at runtime")
        }))
    }
}
