//
//  Expression.swift
//  GRPH Runtime
//
//  Created by Emil Pedersen on 02/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues

protocol RunnableExpression: Expression {
    func eval(context: RuntimeContext) throws -> GRPHValue
}

public extension Expression {
    func evalIfRunnable(context: RuntimeContext) throws -> GRPHValue {
        if let self = self as? RunnableExpression {
            return try self.eval(context: context)
        } else {
            throw GRPHRuntimeError(type: .unexpected, message: "Expression of type \(type(of: self)) has no runnable implementation")
        }
    }
}

extension ConstantExpression: RunnableExpression {
    func eval(context: RuntimeContext) throws -> GRPHValue {
        value
    }
}

extension NullExpression: RunnableExpression {
    func eval(context: RuntimeContext) throws -> GRPHValue {
        GRPHOptional.null
    }
}

extension FunctionReferenceExpression: RunnableExpression {
    func eval(context: RuntimeContext) throws -> GRPHValue {
        FuncRef(currentType: inferredType, storage: .function(function, argumentGrid: argumentGrid))
    }
}
