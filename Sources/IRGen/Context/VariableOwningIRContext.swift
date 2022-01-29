//
//  VariableOwningIRContext.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 29/01/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

class VariableOwningIRContext: IRContext {
    var variables: [Variable] = []
    
    override func findVariable(named name: String) -> Variable? {
        variables.first(where: { $0.name == name }) ?? super.findVariable(named: name)
    }
    
    override func insert(variable: Variable) {
        variables.append(variable)
    }
}
