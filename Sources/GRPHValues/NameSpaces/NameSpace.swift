//
//  NameSpace.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 05/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public protocol NameSpace: Importable {
    /// Must be lowercase !!!
    var name: String { get }
    
}

public extension NameSpace {
    func isEqual(to: NameSpace) -> Bool {
        return name == to.name
    }
}

public struct NameSpaces {
    private init() {}
    
    public static let instances: [NameSpace] =
        [
            StandardNameSpace(),
            InputOutputNameSpace(),
            RandomNameSpace(),
            StringUtilsNameSpace(),
            MathNameSpace(),
            ReflectNameSpace(),
        ]
    
    public static let none: NameSpace = NoNameSpace()
    
    public static func namespace(named name: String) -> NameSpace? {
        return instances.first { $0.name == name.lowercased() }
    }
    
    public static func namespacedMember(from literal: String) -> (namespace: NameSpace?, member: String) {
        if literal.contains(">") {
            let split = literal.split(separator: ">", maxSplits: 1)
            if split.count == 2 {
                return (namespace: namespace(named: String(split[0])), member: String(split[1]))
            }
        }
        return (namespace: none, member: literal)
    }
}

private struct NoNameSpace: NameSpace {
    var name: String { "none" }
}
