//
//  Method.swift
//  Graphism
//
//  Created by Emil Pedersen on 13/07/2020.
//

import Foundation

struct Method: Parametrable, Importable {
    let ns: NameSpace
    let name: String
    /// In this version, inType cannot be a MultiOrType. Create two methods with the same name in the respective types.
    let inType: GRPHType
    let final: Bool
    let parameters: [Parameter]
    let returnType: GRPHType // new in GRPH 1.11, methods can be called with on.name[] syntax
    let varargs: Bool
    let storage: Storage
    
    /// If true, runtime type checks are skipped
    var effectivelyFinal: Bool {
        final || inType.final
    }
    
    var exportedMethods: [Method] { [self] }
    
    init(ns: NameSpace, name: String, inType: GRPHType, final: Bool = false, parameters: [Parameter], returnType: GRPHType = SimpleType.void, varargs: Bool = false, storage: Storage = .native) {
        self.ns = ns
        self.name = name
        self.inType = inType
        self.final = final
        self.parameters = parameters
        self.returnType = returnType
        self.varargs = varargs
        self.storage = storage
    }
}

extension Method {
    enum Storage {
        case native
        case generic(signature: String)
    }
}

extension Method {
    init?(imports: [Importable], namespace: NameSpace, name: String, inType: GRPHType) {
        if namespace.isEqual(to: NameSpaces.none) {
            // when using. either directly imported, either in the namespace, either in the type with an imported namespace
            for imp in imports {
                if let found = imp.exportedMethods.first(where: { $0.name == name && $0.inType.string == inType.string }) {
                    self = found
                    return
                } else if let ns = imp as? NameSpace,
                          let found = inType.includedMethods.first(where: { $0.name == name && $0.ns.isEqual(to: ns) }) {
                    self = found
                    return
                }
            }
            // when importing/using as a namespaced member.
        } else if let found = namespace.exportedMethods.first(where: { $0.name == name && $0.inType.string == inType.string }) {
            self = found
            return
        } else if let found = inType.includedMethods.first(where: { $0.name == name && $0.ns.isEqual(to: namespace) }) {
            self = found
            return
        }
        if inType.isTheMixed {
            return nil
        }
        self.init(imports: imports, namespace: namespace, name: name, inType: inType.supertype)
    }
    
    var fullyQualifiedName: String {
        "\(ns.name == "standard" || ns.name == "none" ? "" : "\(ns.name)>")\(name)"
    }
    
    var signature: String {
        "\(returnType) \(inType).\(fullyQualifiedName)[\(parameters.map { $0.string }.joined(separator: ", "))\(varargs ? "..." : "")]"
    }
}
