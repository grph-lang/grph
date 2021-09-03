//
//  Constructor.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
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
