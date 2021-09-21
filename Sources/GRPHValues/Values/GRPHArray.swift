//
//  GRPHArray.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 30/06/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public class GRPHArray: StatefulValue {
    
    public var wrapped: [GRPHValue]
    public var content: GRPHType
    
    public init(_ wrapped: [GRPHValue] = [], of content: GRPHType) {
        self.wrapped = wrapped
        self.content = content
    }
    
    public init?(byCasting value: GRPHValue) {
        if let val = value as? GRPHArray {
            self.wrapped = val.wrapped // Cast will effectively copy ≠ Java
            self.content = val.content
        } else {
            return nil
        }
    }
    
    public var state: String {
        guard !wrapped.isEmpty else {
            return "{}"
        }
        
        var str = "{"
        for value in wrapped {
            if let value = value as? StatefulValue {
                str += "\(value.state), "
            } else {
                str += "\(value), "
            }
        }
        return "\(str.dropLast(2))}"
    }
    
    public var count: Int { wrapped.count }
    
    public var type: GRPHType { ArrayType(content: content) }
    
    public func isEqual(to other: GRPHValue) -> Bool {
        if let other = other as? GRPHArray,
           other.count == self.count {
            if self === other {
                return true
            }
            for i in 0..<self.count {
                if self.wrapped[i].isEqual(to: other.wrapped[i]) {
                    return false
                }
            }
            return true
        }
        return false
    }
}

extension GRPHArray: CustomStringConvertible {
    public var description: String {
        "<\(content)>\(state)"
    }
}
