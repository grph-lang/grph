//
//  DebuggingCompilingContext.swift
//  Graphism CLI
//
//  Created by Emil Pedersen on 01/09/2021.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import GRPHGenerator
import GRPHRuntime

/// An adapter between RuntimeContext and CompilingContext
class DebuggingCompilingContext: CompilingContext {
    let adapting: RuntimeContext
    
    init(adapting: RuntimeContext, compiler: GRPHCompilerProtocol) {
        self.adapting = adapting
        super.init(compiler: compiler, parent: nil)
    }
    
    override func assertParentNonNil() {
        
    }
    
    override var allVariables: [Variable] { adapting.allVariables }
    
    override func findVariable(named name: String) -> Variable? {
        adapting.findVariable(named: name)
    }
    
    override func findVariableInScope(named name: String) -> Variable? {
        adapting.findVariableInScope(named: name)
    }
    
    override func addVariable(_ variable: Variable, global: Bool) {
        adapting.addVariable(variable, global: global)
    }
}
