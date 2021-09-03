//
//  Importable.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation

protocol Importable {
    var exportedFunctions: [Function] { get }
    var exportedMethods: [Method] { get }
    
    /// Types should be SimpleTypes or custom types, **never** OptionalType, ArrayType, or MultiOrType
    var exportedTypes: [GRPHType] { get }
    
    var exportedTypeAliases: [TypeAlias] { get }
}

extension Importable {
    var exportedFunctions: [Function] { [] }
    var exportedMethods: [Method] { [] }
    var exportedTypes: [GRPHType] { [] }
    var exportedTypeAliases: [TypeAlias] { [] }
}
