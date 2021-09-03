//
//  RadialPaint.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

struct RadialPaint: Paint, Equatable {
    var centerColor: ColorPaint
    var center: Pos = Pos(x: 0.5, y: 0.5)// Unit coordinates (0-1)
    var externalColor: ColorPaint
    var radius: Float
    // Does not support focus :(
    
    var state: String {
        "radial(\(centerColor.state) \(center.state) \(externalColor.state) \(radius))"
    }
    
    var type: GRPHType { SimpleType.radial }
}
