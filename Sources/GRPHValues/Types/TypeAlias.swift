//
//  TypeAlias.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation

struct TypeAlias: Importable {
    let name: String
    let type: GRPHType
    
    var exportedTypeAliases: [TypeAlias] { [self] }
}
