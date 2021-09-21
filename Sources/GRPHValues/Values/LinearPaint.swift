//
//  LinearPaint.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 30/06/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
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
