//
//  Function.swift
//  Graphism
//
//  Created by Emil Pedersen on 06/07/2020.
//

import Foundation
import GRPHValues

extension Function {
    func execute(context: RuntimeContext, arguments: [GRPHValue?]) throws -> GRPHValue {
        switch storage {
        case .native:
            return try NativeFunctionRegistry.shared.implementation(for: self)(context, arguments)
        case .block(let block):
            return try block.executeFunction(context: context, params: arguments)
        }
    }
}
