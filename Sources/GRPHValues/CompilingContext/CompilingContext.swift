//
//  GRPHContext.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 02/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
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
        assert(parent != nil, "parent can only be nil for builtins context")
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
    
    open var globals: GlobalCompilingContext? {
        parent?.globals
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
