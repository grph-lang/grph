//
//  Stroke.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

enum Stroke: String, StatefulValue {
    case elongated, cut, rounded
    
    var state: String { rawValue }
    
    var type: GRPHType { SimpleType.stroke }
    
    var svgLinecap: String {
        switch self {
        case .elongated:
            return "square"
        case .cut:
            return "butt"
        case .rounded:
            return "round"
        }
    }
}


struct StrokeWrapper {
    var strokeWidth: Float = 5
    var strokeType: Stroke = .cut
    var strokeDashArray: GRPHArray = GRPHArray(of: SimpleType.float)
    
    var stateConstructor: String {
        " \(strokeWidth) \(strokeType.rawValue) \(strokeDashArray.state)"
    }
    
    var svgStroke: String {
        #" stroke-width="\#(strokeWidth)" stroke-dasharray="\#(strokeDashArray.wrapped.map { String(describing: $0 as! Float) }.joined(separator: ","))" stroke-linecap="\#(strokeType.svgLinecap)""#
    }
}
