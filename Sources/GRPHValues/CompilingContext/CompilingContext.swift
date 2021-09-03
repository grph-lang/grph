//
//  GRPHContext.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

/// By default, this class is transparent, delegating everything to its parent. VariableOwningCompilingContext overrides that behaviour.
open class CompilingContext: GRPHContextProtocol {
    // Strong reference. Makes it a circular reference. As long as the script is running, this is not a problem. When the script is terminated, context is always deallocated, so the circular reference is broken.
    public let compiler: GRPHCompilerProtocol
    public let parent: CompilingContext?
    
    public init(compiler: GRPHCompilerProtocol, parent: CompilingContext?) {
        self.compiler = compiler
        self.parent = parent
    }
    
    open func assertParentNonNil() {
        assert(parent != nil, "parent can only be nil for top level context")
    }
    
    open var allVariables: [Variable] {
        return parent?.allVariables ?? []
    }
    
    /// Returns in the correct priority. Current scope first, then next scope etc. until global scope
    /// Java version doesn't support multiple variables with the same name even in a different scope. We support it here.
    open func findVariable(named name: String) -> Variable? {
        return parent?.findVariable(named: name)
    }
    
    /// Used in Variable Declaration Instruction to know if defining the variable is allowed
    open func findVariableInScope(named name: String) -> Variable? {
        return parent?.findVariableInScope(named: name)
    }
    
    open func addVariable(_ variable: Variable, global: Bool) {
        parent?.addVariable(variable, global: global)
    }
    
    open func accepts(instruction: Instruction) throws {}
    
    open var inFunction: FunctionDeclarationBlock? {
        parent?.inFunction
    }
    
    public var imports: [Importable] {
        get {
            compiler.imports
        }
        set {
            compiler.imports = newValue
        }
    }
}
