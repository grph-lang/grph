//
//  RadialPaint.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

public struct RadialPaint: Paint, Equatable {
    public var centerColor: ColorPaint
    public var center: Pos = Pos(x: 0.5, y: 0.5) // Unit coordinates (0-1)
    public var externalColor: ColorPaint
    public var radius: Float
    // Does not support focus :(
    
    public init(centerColor: ColorPaint, center: Pos = Pos(x: 0.5, y: 0.5), externalColor: ColorPaint, radius: Float) {
        self.centerColor = centerColor
        self.center = center
        self.externalColor = externalColor
        self.radius = radius
    }
    
    public var state: String {
        "radial(\(centerColor.state) \(center.state) \(externalColor.state) \(radius))"
    }
    
    public var type: GRPHType { SimpleType.radial }
}
