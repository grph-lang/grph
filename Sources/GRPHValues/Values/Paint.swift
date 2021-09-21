//
//  Paint.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 30/06/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
#if GRAPHICAL
import SwiftUI
#endif

public protocol Paint: StatefulValue {
    #if GRAPHICAL
    associatedtype Style: ShapeStyle
    
    func style(shape: GShape) -> Style
    #endif
}

public enum AnyPaint {
    case color(ColorPaint)
    case linear(LinearPaint)
    case radial(RadialPaint)
    
    public var state: String {
        switch self {
        case .color(let color):
            return color.state
        case .linear(let linear):
            return linear.state
        case .radial(let radial):
            return radial.state
        }
    }
    
    static public func auto(_ value: GRPHValue) -> AnyPaint {
        if let value = value as? ColorPaint {
            return .color(value)
        } else if let value = value as? LinearPaint {
            return .linear(value)
        } else if let value = value as? RadialPaint {
            return .radial(value)
        }
        fatalError()
    }
    
    public var unwrapped: GRPHValue {
        switch self {
        case .color(let color):
            return color
        case .linear(let linear):
            return linear
        case .radial(let radial):
            return radial
        }
    }
}
