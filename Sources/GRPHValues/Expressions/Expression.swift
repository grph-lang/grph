//
//  Expression.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 02/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public protocol Expression: CustomStringConvertible, ASTNode {
    
    func getType() -> GRPHType
    
    var string: String { get }
    
    var needsBrackets: Bool { get }
}

public extension Expression {
    var bracketized: String {
        needsBrackets ? "[\(string)]" : string
    }
    
    var description: String {
        string
    }
}
