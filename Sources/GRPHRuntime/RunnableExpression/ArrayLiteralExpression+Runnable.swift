//
//  ArrayLiteralExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
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
