//
//  FunctionCompilingContext.swift
//  Graphism
//
//  Created by Emil Pedersen on 14/07/2020.
//

import Foundation

public class FunctionCompilingContext: VariableOwningCompilingContext {
    public let block: FunctionDeclarationBlock
    
    public init(parent: CompilingContext, function: FunctionDeclarationBlock) {
        self.block = function
        super.init(compiler: parent.compiler, parent: parent)
    }
    
    public override var allVariables: [Variable] {
        var vars = parent!.allVariables.filter { $0.final }
        vars.append(contentsOf: variables)
        return vars
    }
    
    public override func findVariable(named name: String) -> Variable? {
        if let found = variables.first(where: { $0.name == name }) {
            return found
        }
        if let outer = parent?.findVariable(named: name), outer.final {
            return outer
        }
        return nil
    }
    
    public override var inFunction: FunctionDeclarationBlock? { block }
}
