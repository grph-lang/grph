//
//  VariableOwningCompilingContext.swift
//  Graphism
//
//  Created by Emil Pedersen on 26/08/2021.
//

import Foundation

typealias BlockCompilingContext = VariableOwningCompilingContext

class VariableOwningCompilingContext: CompilingContext {
    var variables: [Variable] = []
    
    override var allVariables: [Variable] {
        var vars = super.allVariables
        vars.append(contentsOf: variables)
        return vars
    }
    
    /// Returns in the correct priority. Current scope first, then next scope etc. until global scope
    /// Java version doesn't support multiple variables with the same name even in a different scope. We support it here.
    override func findVariable(named name: String) -> Variable? {
        if let found = findVariableInScope(named: name) {
            return found
        }
        return super.findVariable(named: name)
    }
    
    /// Used in Variable Declaration Instruction to know if defining the variable is allowed
    override func findVariableInScope(named name: String) -> Variable? {
        return variables.first(where: { $0.name == name })
    }
    
    override func addVariable(_ variable: Variable, global: Bool) {
        if global {
            super.addVariable(variable, global: global)
        } else {
            variables.append(variable)
        }
    }
}
