//
//  Constructor.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation
import GRPHValues

extension Constructor {
    func execute(context: RuntimeContext, arguments: [GRPHValue?]) -> GRPHValue {
        NativeFunctionRegistry.shared.implementation(for: self)(type, context, arguments)
    }
}
