//
//  NameSpace.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation
import GRPHValues

protocol ImplementedNameSpace: NameSpace {
    
    func registerImplementations(reg: NativeFunctionRegistry) throws
    
}
extension NameSpaces {
    static func registerAllImplementations(reg: NativeFunctionRegistry) throws {
        try Constructor.registerImplementations(reg: reg)
        for ns in instances {
            if let ns = ns as? ImplementedNameSpace {
                try ns.registerImplementations(reg: reg)
            }
        }
    }
}

extension Array where Element == Function {
    subscript(named name: String) -> Element! {
        get {
            first(where: { $0.name == name })
        }
    }
}

extension Array where Element == Method {
    subscript(named name: String, inType type: GRPHType) -> Element! {
        get {
            first(where: { $0.name == name && $0.inType == type })
        }
    }
}
