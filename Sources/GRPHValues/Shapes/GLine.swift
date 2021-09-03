//
//  GLine.swift
//  Graphism
//
//  Created by Emil Pedersen on 28/06/2020.
//

import Foundation

public class GLine: PaintedShape {
    public var givenName: String?
    public var typeKey: String { "Line" }
    
    public let uuid = UUID()
    
    public var start: Pos
    public var end: Pos
    public var positionZ: Int = 0
    
    public var paint: AnyPaint
    public var strokeStyle: StrokeWrapper?
    
    public init(givenName: String? = nil, start: Pos, end: Pos, positionZ: Int = 0, paint: AnyPaint, strokeStyle: StrokeWrapper? = nil) {
        self.givenName = givenName
        self.start = start
        self.end = end
        self.positionZ = positionZ
        self.paint = paint
        self.strokeStyle = strokeStyle
    }
    
    public var stateDefinitions: String { "" }
    public var stateConstructor: String {
        "Line(\(givenName?.asLiteral ?? "")\(start.state) \(end.state) \(positionZ) \(paint.state)\(strokeStyle?.stateConstructor ?? ""))"
    }
    
    public var type: GRPHType { SimpleType.Line }
    
    public func translate(by diff: Pos) {
        start += diff
        end += diff
    }
    
    public func toSVG<T>(context: SVGExportContext, into out: inout T) where T : TextOutputStream {
        out.writeln(#"<line name="\#(effectiveName)" x1="\#(start.x)" y1="\#(start.y)" x2="\#(end.x)" y2="\#(end.y)" stroke="\#(svgPaint)"\#((strokeStyle ?? StrokeWrapper()).svgStroke) />"#)
    }
}
