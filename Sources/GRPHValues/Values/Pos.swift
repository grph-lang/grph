//
//  Pos.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 30/06/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct Pos: StatefulValue, Equatable {
    public var x: Float
    public var y: Float
    
    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
    
    public var state: String {
        "\(x),\(y)"
    }
    
    public var square: Bool {
        x == y
    }
    
    public var type: GRPHType { SimpleType.pos }
    
    static public func + (lhs: Pos, rhs: Pos) -> Pos {
        Pos(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static public func - (lhs: Pos, rhs: Pos) -> Pos {
        Pos(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    static public func += (lhs: inout Pos, rhs: Pos) {
        lhs = lhs + rhs
    }
}

public extension Pos {
    init?(byCasting value: GRPHValue) {
        if let value = value as? String {
            let components = value.components(separatedBy: ",")
            if components.count == 2,
               let x = Float(components[0]),
               let y = Float(components[1]) {
                self.init(x: x, y: y)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}
