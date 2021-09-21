//
//  SwitchTransparentBlock.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 28/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

/// This is only used at compile time. It is transparent, it is removed by the compiler when it escapes the block. This is not available at runtime, and thus isn't a RunnableInstruction
/// switch blocks are replaced with some #if - #elseif - #else at compile time. This can be seen by enabling WDIU.
public struct SwitchTransparentBlock: BlockInstruction {
    public let lineNumber: Int
    public var children: [Instruction] = []
    // must remain nil
    public var label: String?
    
    public var name: String { "switch" }
    
    public init(lineNumber: Int) {
        self.lineNumber = lineNumber
    }
}
