//
//  SwitchTransparentBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 28/07/2020.
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
}
