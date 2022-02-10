//
//  FunctionIRContext.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 03/02/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues

class FunctionIRContext: VariableOwningIRContext {
    var astNode: FunctionDeclarationBlock
    
    init(parent: IRContext?, astNode: FunctionDeclarationBlock) {
        self.astNode = astNode
        super.init(parent: parent)
    }
    
    override var currentFunction: FunctionDeclarationBlock? {
        astNode
    }
}
