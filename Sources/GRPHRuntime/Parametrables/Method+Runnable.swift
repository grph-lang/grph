//
//  Method.swift
//  GRPH Runtime
//
//  Created by Emil Pedersen on 13/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
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
