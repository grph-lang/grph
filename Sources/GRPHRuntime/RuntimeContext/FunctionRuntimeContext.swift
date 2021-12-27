//
//  FunctionRuntimeContext.swift
//  GRPH Runtime
//
//  Created by Emil Pedersen on 14/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues

class FunctionRuntimeContext: BlockRuntimeContext {
    var currentReturnValue: GRPHValue?
    
    init(parent: RuntimeContext, function: FunctionDeclarationBlock) {
        super.init(parent: parent, block: function)
    }
    
    override var allVariables: [Variable] {
        var vars = parent!.allVariables.filter { $0.final }
        vars.append(contentsOf: variables)
        return vars
    }
    
    override func findVariable(named name: String) -> Variable? {
        if let found = variables.first(where: { $0.name == name }) {
            return found
        }
        if let outer = globals?.findVariable(named: name) {
            return outer
        }
        if let outer = parent?.findVariable(named: name), outer.final {
            // backwards compatibility
            return outer
        }
        return nil
    }
    
    func setReturnValue(returnValue: GRPHValue?) throws {
        currentReturnValue = returnValue // type checked at compile time
    }
}
