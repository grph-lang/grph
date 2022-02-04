//
//  IRContext.swift
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
import GRPHValues

class IRContext {
    var parent: IRContext?
    
    init(parent: IRContext?) {
        self.parent = parent
    }
    
    func findVariable(named name: String) -> Variable? {
        parent?.findVariable(named: name)
    }
    
    func insert(variable: Variable) {
        guard let parent = parent else {
            print("Oops... could not insert variable?")
            return
        }
        parent.insert(variable: variable)
    }
    
    func findBreak(scope: BreakInstruction.BreakScope) -> BlockIRContext? {
        parent?.findBreak(scope: scope)
    }
}
