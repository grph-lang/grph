//
//  LambdaExpression.swift
//  GRPH Runtime
//
//  Created by Emil Pedersen on 26/08/2021.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
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
