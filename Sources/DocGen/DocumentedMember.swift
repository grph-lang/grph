//
//  File.swift
//  File
//
//  Created by Emil Pedersen on 10/09/2021.
//

import Foundation
import GRPHValues
import GRPHGenerator

typealias Method = GRPHValues.Method

protocol DocumentedMember {
    var documentationIdentifier: String { get }
}

extension Function: DocumentedMember {
    var documentationIdentifier: String {
        "function \(signature)"
    }
}

extension Method: DocumentedMember {
    var documentationIdentifier: String {
        "method \(signature)"
    }
}

extension Constructor: DocumentedMember {
    var documentationIdentifier: String {
        "constructor \(signature)"
    }
}

extension Variable: DocumentedMember {
    var documentationIdentifier: String {
        if builtin {
            return "global \(name)"
        } else {
            return ObjectIdentifier(self).debugDescription
        }
    }
}

extension Property/*: DocumentedMember*/ { // humpf
    var documentationIdentifier: String {
        "property \(type).\(name)"
    }
}

extension SemanticToken {
    var documentationIdentifier: String! {
        switch data {
        case .identifier(let id):
            return id
        case .function(let member as DocumentedMember),
               .method(let member as DocumentedMember),
             .variable(let member as DocumentedMember),
          .constructor(let member as DocumentedMember):
            return member.documentationIdentifier
        case .property(let member):
            return member.documentationIdentifier
        case .none:
            switch token.tokenType {
            case .commandName:
                return "command \(token.literal)"
            case .namespace:
                return "namespace \(token.literal)"
            case .enumCase:
                return "case \(token.literal)"
            default:
                return "_unresolvedCompilerError"
            }
        }
    }
}
