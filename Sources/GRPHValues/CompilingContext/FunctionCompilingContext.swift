//
//  FunctionCompilingContext.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 14/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
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
