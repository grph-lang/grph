//
//  Expression.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
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
