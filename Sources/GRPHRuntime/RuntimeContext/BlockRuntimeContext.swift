//
//  BlockRuntimeContext.swift
//  GRPH Runtime
//
//  Created by Emil Pedersen on 25/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues

class BlockRuntimeContext: VariableOwningRuntimeContext {
    let block: BlockInstruction
    
    /// true if the next else can run, false otherwise
    var canNextRun: Bool = true
    /// true if #break or #continue was called in this block
    var broken: Bool = false
    /// true if #continue was called in this block
    var continued: Bool = false
    /// true if #fallthrough was called in this block
    var mustNextRun: Bool = false
    
    init(parent: RuntimeContext, block: BlockInstruction) {
        self.block = block
        super.init(runtime: parent.runtime, parent: parent)
    }
    
    func continueBlock() {
        continued = true
    }
    
    func fallFrom() {
        canNextRun = true
    }
    
    func fallthroughNext() {
        mustNextRun = true
    }
    
    @discardableResult override func breakNearestBlock<T: BlockRuntimeContext>(_ type: T.Type, scope: BreakInstruction.BreakScope = .scopes(1)) throws -> T {
        broken = true
        if let value = self as? T {
            switch scope {
            case .label(let label):
                if block.label == label {
                    return value
                }
            case .scopes(let n):
                if n == 1 {
                    return value
                } else {
                    return try parent!.breakNearestBlock(type, scope: .scopes(n - 1))
                }
            }
        }
        return try parent!.breakNearestBlock(type, scope: scope)
    }
}
