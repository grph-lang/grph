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

/// This is the base context, for top level code. Its parent is always a GlobalCompilingContext
class TopLevelRuntimeContext: VariableOwningRuntimeContext {
    
    public init(runtime: GRPHRuntime) {
        super.init(runtime: runtime, parent: GlobalRuntimeContext(runtime: runtime))
    }
}

/// This context contains all variables declared globals, including ones imported from other files
class GlobalRuntimeContext: VariableOwningRuntimeContext {
    
    public init(runtime: GRPHRuntime) {
        super.init(runtime: runtime, parent: BuiltinsRuntimeContext(runtime: runtime))
    }
    
    public override func addVariable(_ variable: Variable, global: Bool) {
        variables.append(variable)
    }
    
    override var globals: GlobalRuntimeContext? {
        self
    }
}

/// This is the only context that doesn't have a parent. It contains all builtin variables, it can't be modified
class BuiltinsRuntimeContext: VariableOwningRuntimeContext {
    
    public init(runtime: GRPHRuntime) {
        super.init(runtime: runtime, parent: nil)
        variables.append(contentsOf: BuiltinsCompilingContext.defaultVariables.filter { !$0.compileTime } + runtime.initialGlobalVariables)
    }
}
