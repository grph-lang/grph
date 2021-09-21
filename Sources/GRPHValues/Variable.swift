//
//  Variable.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 02/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public class Variable {
    public let name: String
    
    public let type: GRPHType
    
    private(set) public var content: GRPHValue?
    
    public let compileTime: Bool
    public let builtin: Bool
    
    public let final: Bool
    
    public init(name: String, type: GRPHType, content: GRPHValue? = nil, final: Bool, builtin: Bool = false, compileTime: Bool = false) {
        self.name = name
        self.type = type
        self.content = content
        self.final = final
        self.builtin = builtin
        self.compileTime = compileTime
    }
    
    public func setContent(_ content: GRPHValue) throws {
        if final {
            throw GRPHRuntimeError(type: .unexpected, message: "Variable '\(name)' is final")
        }
        self.content = content
    }
}
