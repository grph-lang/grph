//
//  Instruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

protocol Instruction {
    var lineNumber: Int { get }
    
    /// Must end with a newline
    func toString(indent: String) -> String
}

extension Instruction {
    var line: Int {
        lineNumber + 1
    }
}
