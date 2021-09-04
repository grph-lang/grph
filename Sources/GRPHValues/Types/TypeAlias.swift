//
//  TypeAlias.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation

public struct TypeAlias: Importable {
    public let name: String
    public let type: GRPHType
    
    public var exportedTypeAliases: [TypeAlias] { [self] }
    
    public init(name: String, type: GRPHType) {
        self.name = name
        self.type = type
    }
}
