//
//  Constructor.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 05/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct Constructor: Parametrable {
    public let parameters: [Parameter]
    public let type: GRPHType
    public let varargs: Bool
    public let storage: Storage
    
    public init(parameters: [Parameter], type: GRPHType, varargs: Bool = false, storage: Storage) {
        self.parameters = parameters
        self.type = type
        self.varargs = varargs
        self.storage = storage
    }
    
    public var name: String { type.string }
    public var returnType: GRPHType { type }
}

public extension Constructor {
    enum Storage {
        /// The constructor is defined, natively. Ex: SimpleType constructors
        case native
        /// The constructor is generic. Ex: generic types such as arrays, funcrefs. Its implementation is looked up using the given generic signature
        case generic(signature: String)
    }
}

public extension Constructor {
    var signature: String {
        "\(type)(\(parameters.map { $0.string }.joined(separator: ", "))\(varargs ? "..." : ""))"
    }
}
