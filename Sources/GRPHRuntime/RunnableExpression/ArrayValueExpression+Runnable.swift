//
//  ArrayValueExpression.swift
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

extension ArrayValueExpression: RunnableExpression {
    func eval(context: RuntimeContext) throws -> GRPHValue {
        guard let val = try array.evalIfRunnable(context: context) as? GRPHArray else {
            throw GRPHRuntimeError(type: .invalidArgument, message: "Array expression with non-array")
        }
        guard val.count > 0 else {
            throw GRPHRuntimeError(type: .invalidArgument, message: "Index out of bounds; array is empty")
        }
        if let index = index {
            guard let i = try index.evalIfRunnable(context: context) as? Int else {
                throw GRPHRuntimeError(type: .invalidArgument, message: "Array expression index couldn't be resolved as an integer")
            }
            guard i < val.count else {
                throw GRPHRuntimeError(type: .invalidArgument, message: "Index out of bounds; index \(i) not found in array of length \(val.count))")
            }
            if removing {
                return val.wrapped.remove(at: i)
            }
            return val.wrapped[i]
        } else if removing {
            return val.wrapped.removeLast()
        } else {
            return val.wrapped.last!
        }
    }
}
