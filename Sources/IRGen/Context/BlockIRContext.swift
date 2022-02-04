//
//  BlockIRContext.swift
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
import LLVM
import GRPHValues

class BlockIRContext: VariableOwningIRContext {
    var label: String?
    /// The basic block where to branch on a #break
    var breakDestination: BasicBlock
    /// The basic block where to branch on a #continue. If nil, this is not a loop, use the same as #break and issue a warning
    var continueDestination: BasicBlock?
    /// The basic block where to branch on a #fall. If nil, there is no #else branch, use the same as #break and issue a warning
    var fallDestination: BasicBlock?
    /// The basic block where to branch on a #fallthrough. If nil, there is no #else branch, use the same as #break and issue a warning
    var fallthroughDestination: BasicBlock?
    
    init(parent: IRContext?, label: String?,
         `break`: BasicBlock, `continue`: BasicBlock? = nil, fall: BasicBlock? = nil, `fallthrough`: BasicBlock? = nil) {
        self.label = label
        self.breakDestination = `break`
        self.continueDestination = `continue`
        self.fallDestination = fall
        self.fallthroughDestination = `fallthrough`
        super.init(parent: parent)
    }
    
    override func findBreak(scope: BreakInstruction.BreakScope) -> BlockIRContext? {
        switch scope {
        case .scopes(let n):
            if n == 1 {
                return self
            } else {
                return parent?.findBreak(scope: .scopes(n - 1))
            }
        case .label(let label):
            if label == self.label {
                return self
            } else {
                return parent?.findBreak(scope: scope)
            }
        }
    }
}
