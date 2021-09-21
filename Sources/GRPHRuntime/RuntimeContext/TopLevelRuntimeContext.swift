//
//  TopLevelRuntimeContext.swift
//  GRPH Runtime
//
//  Created by Emil Pedersen on 26/08/2021.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
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
