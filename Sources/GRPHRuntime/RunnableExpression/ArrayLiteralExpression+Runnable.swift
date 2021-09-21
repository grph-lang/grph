//
//  ArrayLiteralExpression.swift
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

extension ArrayLiteralExpression: RunnableExpression {
    func eval(context: RuntimeContext) throws -> GRPHValue {
        let array = GRPHArray(of: wrapped)
        for val in values {
            var res = try val.evalIfRunnable(context: context)
            if GRPHTypes.type(of: res, expected: wrapped).isInstance(of: wrapped) {
                // okay
            } else if let int = res as? Int, wrapped as? SimpleType == SimpleType.float { // Backwards compatibility
                res = Float(int)
            } else {
                throw GRPHRuntimeError(type: .invalidArgument, message: "'\(res)' (\(GRPHTypes.type(of: res, expected: wrapped))) is not a valid value in a {\(wrapped)}")
            }
            array.wrapped.append(res)
        }
        return array
    }
}
