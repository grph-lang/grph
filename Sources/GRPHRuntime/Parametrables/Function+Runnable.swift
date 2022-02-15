//
//  Function.swift
//  GRPH Runtime
//
//  Created by Emil Pedersen on 06/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
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
        case .external:
            throw GRPHRuntimeError(type: .unexpected, message: "external function declarations aren't supported in interpreted mode")
        }
    }
}
