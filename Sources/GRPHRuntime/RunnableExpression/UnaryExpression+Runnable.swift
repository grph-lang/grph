//
//  UnaryExpression.swift
//  GRPH Runtime
//
//  Created by Emil Pedersen on 03/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
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
