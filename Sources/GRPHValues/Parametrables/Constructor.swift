//
//  Constructor.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation

struct Constructor: Parametrable {
    let parameters: [Parameter]
    let type: GRPHType
    let varargs: Bool
    let storage: Storage
    
    init(parameters: [Parameter], type: GRPHType, varargs: Bool = false, storage: Storage) {
        self.parameters = parameters
        self.type = type
        self.varargs = varargs
        self.storage = storage
    }
    
    var name: String { type.string }
    var returnType: GRPHType { type }
}

extension Constructor {
    enum Storage {
        /// The constructor is defined, natively. Ex: SimpleType constructors
        case native
        /// The constructor is generic. Ex: generic types such as arrays, funcrefs. Its implementation is looked up using the given generic signature
        case generic(signature: String)
    }
}

extension Constructor {
    var signature: String {
        "\(type)(\(parameters.map { $0.string }.joined(separator: ", "))\(varargs ? "..." : ""))"
    }
}
