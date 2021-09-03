//
//  SwitchTransparentBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 28/07/2020.
//

import Foundation

/// This is only used at compile time. It is transparent, it is removed by the compiler when it escapes the block. This is not available at runtime, and thus isn't a RunnableInstruction
/// switch blocks are replaced with some #if - #elseif - #else at compile time. This can be seen by enabling WDIU.
struct SwitchTransparentBlock: BlockInstruction {
    let lineNumber: Int
    var children: [Instruction] = []
    // must remain nil
    var label: String?
    
    var name: String { "switch" }
}
