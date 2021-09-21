//
//  TryBlock.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 04/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct TryBlock: BlockInstruction {
    public let lineNumber: Int
    public var children: [Instruction] = []
    public var label: String?
    public var catches: [GRPHRuntimeError.RuntimeExceptionType?: CatchBlock] = [:]
    
    public init(context: inout CompilingContext, lineNumber: Int) {
        self.lineNumber = lineNumber
        createContext(&context)
    }
    
    public var name: String { "try" }
}
