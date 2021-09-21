//
//  VirtualAssignmentRuntimeContext.swift
//  GRPH Runtime
//
//  Created by Emil Pedersen on 26/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues

class VirtualAssignmentRuntimeContext: RuntimeContext {
    let virtualValue: GRPHValue
    
    init(parent: RuntimeContext, virtualValue: GRPHValue) {
        self.virtualValue = virtualValue
        super.init(runtime: parent.runtime, parent: parent)
    }
}
