//
//  GLine.swift
//  Graphism
//
//  Created by Emil Pedersen on 28/06/2020.
//

import Foundation

class GLine: PaintedShape {
    var givenName: String?
    var typeKey: String { "Line" }
    
    let uuid = UUID()
    
    var start: Pos
    var end: Pos
    var positionZ: Int = 0
    
    var paint: AnyPaint
    var strokeStyle: StrokeWrapper?
    
    init(givenName: String? = nil, start: Pos, end: Pos, positionZ: Int = 0, paint: AnyPaint, strokeStyle: StrokeWrapper? = nil) {
        self.givenName = givenName
        self.start = start
        self.end = end
        self.positionZ = positionZ
        self.paint = paint
        self.strokeStyle = strokeStyle
    }
    
    var stateDefinitions: String { "" }
    var stateConstructor: String {
        "Line(\(givenName?.asLiteral ?? "")\(start.state) \(end.state) \(positionZ) \(paint.state)\(strokeStyle?.stateConstructor ?? ""))"
    }
    
    var type: GRPHType { SimpleType.Line }
    
    func translate(by diff: Pos) {
        start += diff
        end += diff
    }
    
    func toSVG<T>(context: SVGExportContext, into out: inout T) where T : TextOutputStream {
        out.writeln(#"<line name="\#(effectiveName)" x1="\#(start.x)" y1="\#(start.y)" x2="\#(end.x)" y2="\#(end.y)" stroke="\#(svgPaint)"\#((strokeStyle ?? StrokeWrapper()).svgStroke) />"#)
    }
}
