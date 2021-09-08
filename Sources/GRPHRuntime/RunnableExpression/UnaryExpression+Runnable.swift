//
//  UnaryExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation
import GRPHValues

extension UnaryExpression: RunnableExpression {
    func eval(context: RuntimeContext) throws -> GRPHValue {
        let evaluated = try GRPHTypes.unbox(value: exp.evalIfRunnable(context: context))
        switch op {
        case .bitwiseComplement:
            return ~(evaluated as! Int)
        case .opposite:
            if let value = evaluated as? Int {
                return -value
            }
            return -(evaluated as! Float)
        case .not:
            return !(evaluated as! Bool)
        }
    }
}

extension UnboxExpression: RunnableExpression {
    func eval(context: RuntimeContext) throws -> GRPHValue {
        let value = try exp.evalIfRunnable(context: context)
        guard let opt = value as? GRPHOptional else {
            throw GRPHRuntimeError(type: .unexpected, message: "Cannot unbox non optional")
        }
        switch opt {
        case .null:
            throw GRPHRuntimeError(type: .cast, message: "Tried to unbox a 'null' value")
        case .some(let wrapped):
            return wrapped
        }
    }
}
