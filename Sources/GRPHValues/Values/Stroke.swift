//
//  Stroke.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

public enum Stroke: String, StatefulValue {
    case elongated, cut, rounded
    
    public var state: String { rawValue }
    
    public var type: GRPHType { SimpleType.stroke }
    
    public var svgLinecap: String {
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


public struct StrokeWrapper {
    public var strokeWidth: Float = 5
    public var strokeType: Stroke = .cut
    public var strokeDashArray: GRPHArray = GRPHArray(of: SimpleType.float)
    
    public init(strokeWidth: Float = 5, strokeType: Stroke = .cut, strokeDashArray: GRPHArray = GRPHArray(of: SimpleType.float)) {
        self.strokeWidth = strokeWidth
        self.strokeType = strokeType
        self.strokeDashArray = strokeDashArray
    }
    
    public var stateConstructor: String {
        " \(strokeWidth) \(strokeType.rawValue) \(strokeDashArray.state)"
    }
    
    public var svgStroke: String {
        #" stroke-width="\#(strokeWidth)" stroke-dasharray="\#(strokeDashArray.wrapped.map { String(describing: $0 as! Float) }.joined(separator: ","))" stroke-linecap="\#(strokeType.svgLinecap)""#
    }
}
