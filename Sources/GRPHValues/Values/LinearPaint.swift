//
//  LinearPaint.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

public struct LinearPaint: Paint, Equatable {
    public var from: ColorPaint
    public var direction: Direction
    public var to: ColorPaint
    
    public init(from: ColorPaint, direction: Direction, to: ColorPaint) {
        self.from = from
        self.direction = direction
        self.to = to
    }
    
    public var state: String {
        "linear(\(from.state) \(direction.rawValue) \(to.state))"
    }
    
    public var type: GRPHType { SimpleType.linear }
}
