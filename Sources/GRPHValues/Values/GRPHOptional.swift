//
//  GRPHOptional.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation

// A type-erased Optional, used in GRPH
enum GRPHOptional: GRPHValue {
    
    case null
    case some(GRPHValue)
    
    var type: GRPHType {
        switch self {
        case .null:
            return OptionalType(wrapped: SimpleType.mixed) // Type inference is done in GRPHType.realType(of:expected:)
        case .some(let value):
            return OptionalType(wrapped: value.type)
        }
    }
    
    var isEmpty: Bool {
        switch self {
        case .null:
            return true
        case .some(_):
            return false
        }
    }
    
    func isEqual(to other: GRPHValue) -> Bool {
        if let other = other as? GRPHOptional {
            if case .some(let value) = other {
                if case .some(let mine) = self {
                    return value.isEqual(to: mine)
                }
            } else if case .null = self {
                return true
            }
        }
        return false
    }
    
    init(_ value: GRPHValue?) {
        if let value = value {
            self = .some(value)
        } else {
            self = .null
        }
    }
    
    var content: GRPHValue? {
        switch self {
        case .null:
            return nil
        case .some(let value):
            return value
        }
    }
}

extension GRPHOptional: CustomStringConvertible {
    var description: String {
        switch self {
        case .null:
            return "null"
        case .some(let value):
            return "Optional[\(value)]"
        }
    }
}
