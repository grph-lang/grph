//
//  Function.swift
//  Graphism
//
//  Created by Emil Pedersen on 06/07/2020.
//

import Foundation

struct Function: Parametrable, Importable {
    let ns: NameSpace
    let name: String
    let parameters: [Parameter]
    let returnType: GRPHType
    let varargs: Bool
    let storage: Storage
    
    init(ns: NameSpace, name: String, parameters: [Parameter], returnType: GRPHType = SimpleType.void, varargs: Bool = false, storage: Storage = .native) {
        self.ns = ns
        self.name = name
        self.parameters = parameters
        self.returnType = returnType
        self.varargs = varargs
        self.storage = storage
    }
    
    var exportedFunctions: [Function] { [self] }
}

extension Function {
    enum Storage {
        case native
        case block(FunctionDeclarationBlock)
    }
}

extension Function {
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
        "\(returnType) \(fullyQualifiedName)[\(parameters.map { $0.string }.joined(separator: ", "))\(varargs ? "..." : "")]"
    }
}
