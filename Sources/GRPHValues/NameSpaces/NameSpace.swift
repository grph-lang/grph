//
//  NameSpace.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation

protocol NameSpace: Importable {
    /// Must be lowercase !!!
    var name: String { get }
    
}

extension NameSpace {
    func isEqual(to: NameSpace) -> Bool {
        return name == to.name
    }
}

struct NameSpaces {
    private init() {}
    
    static let instances: [NameSpace] =
        [
            StandardNameSpace(),
            InputOutputNameSpace(),
            RandomNameSpace(),
            StringUtilsNameSpace(),
            MathNameSpace(),
            ReflectNameSpace(),
        ]
    
    static let none: NameSpace = NoNameSpace()
    
    static func namespace(named name: String) -> NameSpace? {
        return instances.first { $0.name == name.lowercased() }
    }
    
    static func namespacedMember(from literal: String) -> (namespace: NameSpace?, member: String) {
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
