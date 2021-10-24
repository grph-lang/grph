//
//  GRPHTuple.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 30/06/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

// tuples, unlike arrays, are structs, and are copied around
public struct GRPHTuple: StatefulValue {
    public var wrapped: [GRPHValue]
    public var types: TupleType
    
    public init(_ wrapped: [GRPHValue] = [], of type: TupleType) {
        assert(type.content.count == wrapped.count, "Incompatible tuple size")
        self.wrapped = wrapped
        self.types = type
    }
    
    public init?(byCasting value: GRPHValue) {
        if let val = value as? GRPHTuple {
            self = val
        } else {
            return nil
        }
    }
    
    public var state: String {
        guard !wrapped.isEmpty else {
            return "()"
        }
        
        var str = "("
        for value in wrapped {
            if let value = value as? StatefulValue {
                str += "\(value.state) "
            } else {
                str += "\(value) "
            }
        }
        return "\(str.dropLast()))"
    }
    
    public var count: Int { wrapped.count }
    
    public var type: GRPHType { types }
    
    public func isEqual(to other: GRPHValue) -> Bool {
        if let other = other as? GRPHTuple,
           other.count == self.count {
            for i in 0..<self.count {
                if !self.wrapped[i].isEqual(to: other.wrapped[i]) {
                    return false
                }
            }
            return true
        }
        return false
    }
}

extension GRPHTuple: CustomStringConvertible {
    public var description: String {
        "<\(type)>\(state)"
    }
}
