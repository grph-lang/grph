//
//  Variable.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

public class Variable {
    public let name: String
    
    public let type: GRPHType
    
    private(set) public var content: GRPHValue?
    
    public let compileTime: Bool
    
    public let final: Bool
    
    public init(name: String, type: GRPHType, content: GRPHValue? = nil, final: Bool, compileTime: Bool = false) {
        self.name = name
        self.type = type
        self.content = content
        self.final = final
        self.compileTime = compileTime
    }
    
    public func setContent(_ content: GRPHValue) throws {
        if final {
            throw GRPHRuntimeError(type: .unexpected, message: "Variable '\(name)' is final")
        }
        self.content = content
    }
}
