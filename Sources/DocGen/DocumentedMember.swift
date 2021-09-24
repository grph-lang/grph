//
//  DocumentedMember.swift
//  GRPH DocGen
//
//  Created by Emil Pedersen on 10/09/2021.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import GRPHGenerator

typealias Method = GRPHValues.Method

protocol DocumentedMember {
    /// The unique identifier for this member
    var documentationIdentifier: String { get }
    
    /// The different names which may link to this member when using `@see`
    var documentationNames: [String] { get }
}

extension Function: DocumentedMember {
    var documentationIdentifier: String {
        "function \(signature)"
    }
    
    var documentationNames: [String] {
        [documentationIdentifier, fullyQualifiedName, name, signature]
    }
}

extension Method: DocumentedMember {
    var documentationIdentifier: String {
        "method \(signature)"
    }
    
    var documentationNames: [String] {
        [documentationIdentifier, fullyQualifiedName, name, signature]
    }
}

extension Constructor: DocumentedMember {
    var documentationIdentifier: String {
        "constructor \(signature)"
    }
    
    var documentationNames: [String] {
        [documentationIdentifier, name, "constructor \(name)", signature]
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
    
    var documentationNames: [String] {
        [documentationIdentifier, name]
    }
}

extension Property/*: DocumentedMember*/ { // humpf (can't for two reasons)
    func documentationIdentifier(in inType: GRPHType) -> String {
        "property \(inType).\(name)"
    }
    
    func documentationNames(in inType: GRPHType) -> [String] {
        [documentationIdentifier(in: inType), name, "\(inType).\(name)"]
    }
}

extension SemanticToken {
    var documentationIdentifier: String? {
        switch data {
        case .identifier(let id):
            return id
        case .function(let member as DocumentedMember),
               .method(let member as DocumentedMember),
             .variable(let member as DocumentedMember),
          .constructor(let member as DocumentedMember):
            return member.documentationIdentifier
        case .property(let member, in: let type):
            return member.documentationIdentifier(in: type)
        case .none:
            switch token.tokenType {
            case .commandName:
                return "command \(token.literal)"
            case .namespace:
                return "namespace \(token.literal)"
            case .enumCase:
                return "case \(token.literal)"
            default:
                return nil
            }
        }
    }
    
    var documentationNames: [String] {
        switch data {
        case .identifier(let id): // namespaces, variables, commands
            return [id, id.components(separatedBy: " ").last!]
        case .function(let member as DocumentedMember),
               .method(let member as DocumentedMember),
             .variable(let member as DocumentedMember),
          .constructor(let member as DocumentedMember):
            return member.documentationNames
        case .property(let member, in: let type):
            return member.documentationNames(in: type)
        case .none:
            switch token.tokenType {
            case .commandName:
                return ["command \(token.literal)", token.description]
            case .namespace:
                return ["namespace \(token.literal)", token.description]
            case .enumCase:
                return ["case \(token.literal)", token.description]
            default:
                return []
            }
        }
    }
}
