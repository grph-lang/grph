//
//  Variable.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

class Variable {
    let name: String
    
    let type: GRPHType
    
    private(set) var content: GRPHValue?
    
    let compileTime: Bool
    
    let final: Bool
    
    init(name: String, type: GRPHType, content: GRPHValue? = nil, final: Bool, compileTime: Bool = false) {
        self.name = name
        self.type = type
        self.content = content
        self.final = final
        self.compileTime = compileTime
    }
    
    func setContent(_ content: GRPHValue) throws {
        if final {
            throw GRPHRuntimeError(type: .unexpected, message: "Variable '\(name)' is final")
        }
        self.content = content
    }
}
