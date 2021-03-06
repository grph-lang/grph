//
//  Direction.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 30/06/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public enum Direction: String, StatefulValue, CaseIterable {
    case right, downRight, down, downLeft, left, upLeft, up, upRight
    
    public var reverse: Direction {
        switch self {
        case .right:
            return .left
        case .downRight:
            return .upLeft
        case .down:
            return .up
        case .downLeft:
            return .upRight
        case .left:
            return .right
        case .upLeft:
            return .downRight
        case .up:
            return .down
        case .upRight:
            return .downLeft
        }
    }
    
    public var state: String { rawValue }
    
    public var type: GRPHType { SimpleType.direction }
}

public extension Direction {
    var pointingTowards: (x: Double, y: Double) {
        switch self {
        case .right:
            return (1, 0.5)
        case .downRight:
            return (1, 1)
        case .down:
            return (0.5, 1)
        case .downLeft:
            return (0, 1)
        case .left:
            return (0, 0.5)
        case .upLeft:
            return (0, 0)
        case .up:
            return (0.5, 0)
        case .upRight:
            return (1, 0)
        }
    }
}

