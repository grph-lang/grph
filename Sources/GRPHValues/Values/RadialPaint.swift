//
//  RadialPaint.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 30/06/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
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
