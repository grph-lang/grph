//
//  NameSpace.swift
//  GRPH Runtime
//
//  Created by Emil Pedersen on 05/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
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
