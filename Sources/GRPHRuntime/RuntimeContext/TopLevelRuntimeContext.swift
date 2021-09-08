//
//  TopLevelRuntimeContext.swift
//  Graphism
//
//  Created by Emil Pedersen on 26/08/2021.
//

import Foundation
import GRPHValues

/// This is the only context that doesn't have a parent
class TopLevelRuntimeContext: VariableOwningRuntimeContext {
    
    init(runtime: GRPHRuntime) {
        super.init(runtime: runtime, parent: nil)
        variables.append(contentsOf: runtime.initialGlobalVariables)
    }
    
    override func addVariable(_ variable: Variable, global: Bool) {
        variables.append(variable)
    }
}
