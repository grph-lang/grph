//
//  Instruction.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 02/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public protocol Instruction: AnyObject {
    var lineNumber: Int { get }
    
    /// Must end with a newline
    func toString(indent: String) -> String
}

public extension Instruction {
    var line: Int {
        lineNumber + 1
    }
}
