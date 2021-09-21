//
//  GRPHType.swift
//  GRPH Runtime
//
//  Created by Emil Pedersen on 30/06/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues

extension GRPHTypes {
    /// Type of a value is calculated HERE
    /// It uses GRPHValue.type but takes into account AUTOBOXING and AUTOUNBOXING, based on expected.
    /// Also, type of null is inferred here
    static func type(of value: GRPHValue, expected: GRPHType? = nil) -> GRPHType {
        return autoboxed(type: realType(of: value, expected: expected), expected: expected)
    }
    
    static func autobox(value: GRPHValue, expected: GRPHType) throws -> GRPHValue {
        if let value = value as? GRPHOptional {
            if let expected = expected as? OptionalType { // recursive
                switch value {
                case .null:
                    return value
                case .some(let wrapped):
                    return GRPHOptional.some(try autobox(value: wrapped, expected: expected.wrapped))
                }
            } else { // Unboxing
                switch value {
                case .null:
                    throw GRPHRuntimeError(type: .cast, message: "Tried to auto-unbox a 'null' value")
                case .some(let wrapped):
                    return try autobox(value: wrapped, expected: expected) // Unboxing
                }
            }
        } else if let expected = expected as? OptionalType { // Boxing
            return GRPHOptional.some(try autobox(value: value, expected: expected.wrapped))
        } else {
            return value
        }
    }
    
    /// Use this instead of autobox if you always expect an unwrapped value, as it's faster
    static func unbox(value: GRPHValue) throws -> GRPHValue {
        if let value = value as? GRPHOptional {
            switch value {
            case .null:
                throw GRPHRuntimeError(type: .typeMismatch, message: "Tried to auto-unbox a 'null' value")
            case .some(let wrapped):
                return try unbox(value: wrapped) // Unboxing
            }
        } else {
            return value
        }
    }
    
    static func realType(of value: GRPHValue, expected: GRPHType?) -> GRPHType {
        if let value = value as? GRPHOptional,
           value.isEmpty,
           expected is OptionalType {
            return expected ?? SimpleType.mixed.optional
        }
        return value.type
    }
}
