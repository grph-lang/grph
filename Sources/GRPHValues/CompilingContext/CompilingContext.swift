//
//  GRPHContext.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

/// By default, this class is transparent, delegating everything to its parent. VariableOwningCompilingContext overrides that behaviour.
class CompilingContext: GRPHContextProtocol {
    // Strong reference. Makes it a circular reference. As long as the script is running, this is not a problem. When the script is terminated, context is always deallocated, so the circular reference is broken.
    let compiler: GRPHCompilerProtocol
    let parent: CompilingContext?
    
    init(compiler: GRPHCompilerProtocol, parent: CompilingContext?) {
        self.compiler = compiler
        self.parent = parent
    }
    
    func assertParentNonNil() {
        assert(parent != nil, "parent can only be nil for top level context")
    }
    
    var allVariables: [Variable] {
        return parent?.allVariables ?? []
    }
    
    /// Returns in the correct priority. Current scope first, then next scope etc. until global scope
    /// Java version doesn't support multiple variables with the same name even in a different scope. We support it here.
    func findVariable(named name: String) -> Variable? {
        return parent?.findVariable(named: name)
    }
    
    /// Used in Variable Declaration Instruction to know if defining the variable is allowed
    func findVariableInScope(named name: String) -> Variable? {
        return parent?.findVariableInScope(named: name)
    }
    
    func addVariable(_ variable: Variable, global: Bool) {
        parent?.addVariable(variable, global: global)
    }
    
    func accepts(instruction: Instruction) throws {}
    
    var inFunction: FunctionDeclarationBlock? {
        parent?.inFunction
    }
    
    var imports: [Importable] {
        get {
            compiler.imports
        }
        set {
            compiler.imports = newValue
        }
    }
}
