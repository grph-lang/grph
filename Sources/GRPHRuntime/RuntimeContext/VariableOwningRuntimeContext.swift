//
//  VariableOwningRuntimeContext.swift
//  Graphism
//
//  Created by Emil Pedersen on 26/08/2021.
//

import Foundation
import GRPHValues

class VariableOwningRuntimeContext: RuntimeContext {
    
    var variables: [Variable] = []
    
    deinit {
        if runtime.debugging {
            for variable in variables {
                printout("[DEBUG -VAR \(variable.name)]")
            }
        }
    }
    
    override var allVariables: [Variable] {
        var vars = super.allVariables
        vars.append(contentsOf: variables)
        return vars
    }
    
    /// Returns in the correct priority. Current scope first, then next scope etc. until global scope
    /// Java version doesn't support multiple variables with the same name even in a different scope. We support it here.
    override func findVariable(named name: String) -> Variable? {
        if let found = variables.first(where: { $0.name == name }) {
            return found
        }
        return super.findVariable(named: name)
    }
    
    /// Used in Variable Declaration Instruction to know if defining the variable is allowed
    override func findVariableInScope(named name: String) -> Variable? {
        if let found = variables.first(where: { $0.name == name }) {
            return found
        }
        return nil
    }
    
    override func addVariable(_ variable: Variable, global: Bool) {
        if global {
            super.addVariable(variable, global: global)
        } else {
            variables.append(variable)
        }
    }
}

typealias LambdaRuntimeContext = VariableOwningRuntimeContext
