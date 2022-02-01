//
//  CastExpression.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 03/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct CastExpression: Expression {
    public let from: Expression
    public let cast: CastType
    public let to: GRPHType
    
    public init(from: Expression, cast: CastType, to: GRPHType) {
        self.from = from
        self.cast = cast
        self.to = to
    }
    
    public func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        if case .typeCheck = cast {
            return SimpleType.boolean
        } else if cast.optional {
            return to.optional
        } else {
            return to
        }
    }
    
    public var string: String { "\(from.bracketized) \(cast.string) \(to.string)" }
    
    public var needsBrackets: Bool { true }
}

public extension CastExpression {
    var astNodeData: String {
        switch cast {
        case .typeCheck:
            return "check if of type \(to)"
        case .conversion(true):
            return "optional conversion to \(to)"
        case .conversion(false):
            return "throwing conversion to \(to)"
        case .strict(true):
            return "optional downcast to \(to)"
        case .strict(false):
            return "throwing downcast to \(to)"
        }
    }
    
    var astChildren: [ASTElement] {
        [
            ASTElement(name: "value", value: [from])
        ]
    }
}

public enum CastType {
    case typeCheck
    case conversion(optional: Bool)
    case strict(optional: Bool)
    
    public var string: String {
        switch self {
        case .typeCheck:
            return "is"
        case .conversion(optional: let optional):
            return "as\(optional ? "?" : "")"
        case .strict(optional: let optional):
            return "as\(optional ? "?" : "")!"
        }
    }
    
    public init?(_ str: String) {
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
    
    public var optional: Bool {
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
