//
//  Pos.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

struct Pos: StatefulValue, Equatable {
    var x: Float
    var y: Float
    
    var state: String {
        "\(x),\(y)"
    }
    
    var square: Bool {
        x == y
    }
    
    var type: GRPHType { SimpleType.pos }
    
    static func + (lhs: Pos, rhs: Pos) -> Pos {
        Pos(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func - (lhs: Pos, rhs: Pos) -> Pos {
        Pos(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    static func += (lhs: inout Pos, rhs: Pos) {
        lhs = lhs + rhs
    }
}

extension Pos {
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
