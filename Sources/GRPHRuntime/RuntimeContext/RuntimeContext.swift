//
//  RuntimeContext.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation
import GRPHValues

class RuntimeContext: GRPHContextProtocol {
    // Strong reference. Makes it a circular reference. As long as the script is running, this is not a problem. When the script is terminated, context is always deallocated, so the circular reference is broken.
    let runtime: GRPHRuntime
    
    var parent: RuntimeContext?
    var previous: RuntimeContext?
    
    init(runtime: GRPHRuntime, parent: RuntimeContext?) {
        self.runtime = runtime
        self.parent = parent
        assert(parent != nil || self is TopLevelRuntimeContext, "parent can only be nil for top level context")
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
    
    final func breakBlock(scope: BreakInstruction.BreakScope) throws {
        try breakNearestBlock(BlockRuntimeContext.self, scope: scope)
    }
    
    final func continueBlock(scope: BreakInstruction.BreakScope) throws {
        try breakNearestBlock(BlockRuntimeContext.self, scope: scope).continueBlock()
    }
    
    final func fallFromBlock(scope: BreakInstruction.BreakScope) throws {
        try breakNearestBlock(BlockRuntimeContext.self, scope: scope).fallFrom()
    }
    
    final func fallthroughNextBlock(scope: BreakInstruction.BreakScope) throws {
        try breakNearestBlock(BlockRuntimeContext.self, scope: scope).fallthroughNext()
    }
    
    final func returnFunction(returnValue: GRPHValue?) throws {
        try breakNearestBlock(FunctionRuntimeContext.self).setReturnValue(returnValue: returnValue)
    }
    
    @discardableResult func breakNearestBlock<T: BlockRuntimeContext>(_ type: T.Type, scope: BreakInstruction.BreakScope = .scopes(1)) throws -> T {
        throw GRPHRuntimeError(type: .unexpected, message: "Couldn't break out")
    }
    
    var imports: [Importable] { runtime.imports }
}
