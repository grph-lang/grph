//
//  Instruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

public protocol Instruction {
    var lineNumber: Int { get }
    
    /// Must end with a newline
    func toString(indent: String) -> String
}

public extension Instruction {
    var line: Int {
        lineNumber + 1
    }
}
