//
//  Importable.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 05/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public protocol Importable {
    var exportedFunctions: [Function] { get }
    var exportedMethods: [Method] { get }
    
    /// Types should be SimpleTypes or custom types, **never** OptionalType, ArrayType, or MultiOrType
    var exportedTypes: [GRPHType] { get }
    
    var exportedTypeAliases: [TypeAlias] { get }
}

public extension Importable {
    var exportedFunctions: [Function] { [] }
    var exportedMethods: [Method] { [] }
    var exportedTypes: [GRPHType] { [] }
    var exportedTypeAliases: [TypeAlias] { [] }
}
