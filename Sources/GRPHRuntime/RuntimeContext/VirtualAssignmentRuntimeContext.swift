//
//  VirtualAssignmentRuntimeContext.swift
//  Graphism
//
//  Created by Emil Pedersen on 26/07/2020.
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
