//
//  CastExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation

struct CastExpression: Expression {
    let from: Expression
    let cast: CastType
    let to: GRPHType
    
    func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        if case .typeCheck = cast {
            return SimpleType.boolean
        } else if cast.optional {
            return to.optional
        } else {
            return to
        }
    }
    
    var string: String { "\(from.string) \(cast.string) \(to.string)" }
    
    var needsBrackets: Bool { true }
}

enum CastType {
    case typeCheck
    case conversion(optional: Bool)
    case strict(optional: Bool)
    
    var string: String {
        switch self {
        case .typeCheck:
            return "is"
        case .conversion(optional: let optional):
            return "as\(optional ? "?" : "")"
        case .strict(optional: let optional):
            return "as\(optional ? "?" : "")!"
        }
    }
    
    init?(_ str: String) {
        if str == "is" {
            self = .typeCheck
        } else if str.hasPrefix("as") {
            let optional = str.dropFirst(2).hasPrefix("?")
            if str.hasSuffix("!") {
                self = .strict(optional: optional)
            } else {
                self = .conversion(optional: optional)
            }
        } else {
            return nil
        }
    }
    
    var optional: Bool {
        switch self {
        case .typeCheck:
            return false
        case .conversion(optional: let optional):
            return optional
        case .strict(optional: let optional):
            return optional
        }
    }
}
