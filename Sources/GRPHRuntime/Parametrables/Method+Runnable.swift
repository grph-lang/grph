//
//  Method.swift
//  Graphism
//
//  Created by Emil Pedersen on 13/07/2020.
//

import Foundation
import GRPHValues

extension Method {
    func execute(context: RuntimeContext, on: GRPHValue, arguments: [GRPHValue?]) throws -> GRPHValue {
        switch storage {
        case .native:
            return try NativeFunctionRegistry.shared.implementation(for: self)(context, on, arguments)
        case .generic(signature: let signature):
            return try NativeFunctionRegistry.shared.implementation(forMethodWithGenericSignature: signature)(context, on, arguments)
        }
    }
}
