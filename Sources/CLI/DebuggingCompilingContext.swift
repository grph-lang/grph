//
//  DebuggingCompilingContext.swift
//  DebuggingCompilingContext
//
//  Created by Emil Pedersen on 01/09/2021.
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
