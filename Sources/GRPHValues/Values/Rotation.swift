//
//  Rotation.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 30/06/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct Rotation: StatefulValue, ExpressibleByIntegerLiteral, Equatable, CustomStringConvertible {
    private var _value: Int
    
    public var value: Int {
        get {
            _value
        }
        set {
            // Normalize: -180 < value ≤ 180
            var v = newValue % 360
            if v <= -180 {
                v += 360
            }
            if v > 180 {
                v -= 360
            }
            _value = v
        }
    }
    
    public var state: String {
        "\(value)°"
    }
    
    public var description: String { value.description }
    
    public init(integerLiteral value: Int) {
        self.init(value: value)
    }
    
    public init(value: Int) {
        self._value = value
        self.value = value // normalize
    }
    
    public init?(byCasting value: GRPHValue) {
        if let value = value as? Int {
            self.init(value: value)
            return
        } else if let value = value as? Float {
            self.init(value: Int(value))
            return
        } else if let value = value as? String {
            if value.hasSuffix("º") || value.hasSuffix("°") {
                if let i = Int(decoding: value.dropLast()) {
                    self.init(value: i)
                    return
                }
            } else if let i = Int(decoding: value) {
                self.init(value: i)
                return
            }
        }
        return nil
    }
    
    public var type: GRPHType { SimpleType.rotation }
    
    static public func + (lhs: Rotation, rhs: Rotation) -> Rotation {
        Rotation(value: lhs.value + rhs.value)
    }
    
    static public func - (lhs: Rotation, rhs: Rotation) -> Rotation {
        Rotation(value: lhs.value - rhs.value)
    }
}
