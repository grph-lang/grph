//
//  Rotation.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

struct Rotation: StatefulValue, ExpressibleByIntegerLiteral, Equatable, CustomStringConvertible {
    private var _value: Int
    
    var value: Int {
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
    
    var state: String {
        "\(value)°"
    }
    
    var description: String { value.description }
    
    init(integerLiteral value: Int) {
        self.init(value: value)
    }
    
    init(value: Int) {
        self._value = value
        self.value = value // normalize
    }
    
    init?(byCasting value: GRPHValue) {
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
    
    var type: GRPHType { SimpleType.rotation }
    
    static func + (lhs: Rotation, rhs: Rotation) -> Rotation {
        Rotation(value: lhs.value + rhs.value)
    }
    
    static func - (lhs: Rotation, rhs: Rotation) -> Rotation {
        Rotation(value: lhs.value - rhs.value)
    }
}
