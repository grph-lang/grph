//
//  TypeAlias.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 05/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
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
