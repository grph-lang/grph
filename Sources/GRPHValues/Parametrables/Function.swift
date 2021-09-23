//
//  Function.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 06/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct Function: Parametrable, Importable {
    public let ns: NameSpace
    public let name: String
    public let parameters: [Parameter]
    public let returnType: GRPHType
    public let varargs: Bool
    public let storage: Storage
    
    public init(ns: NameSpace, name: String, parameters: [Parameter], returnType: GRPHType = SimpleType.void, varargs: Bool = false, storage: Storage = .native) {
        self.ns = ns
        self.name = name
        self.parameters = parameters
        self.returnType = returnType
        self.varargs = varargs
        self.storage = storage
    }
    
    public var exportedFunctions: [Function] { [self] }
}

public extension Function {
    enum Storage {
        case native
        case block(FunctionDeclarationBlock)
    }
}

public extension Function {
    init?(imports: [Importable], namespace: NameSpace, name: String) {
        if namespace.isEqual(to: NameSpaces.none) {
            for imp in imports {
                if let found = imp.exportedFunctions.first(where: { $0.name == name }) {
                    self = found
                    return
                }
            }
        } else if let found = namespace.exportedFunctions.first(where: { $0.name == name }) {
            self = found
            return
        }
        return nil
    }
    
    var fullyQualifiedName: String {
        "\(ns.name == "standard" || ns.name == "none" ? "" : "\(ns.name)>")\(name)"
    }
    
    var signature: String {
        "\(returnType) \(fullyQualifiedName)[\(parameters.map { $0.string }.joined(separator: ", "))\(varargs && !(parameters.last?.name.hasSuffix("...") ?? false) ? "..." : "")]"
    }
}
