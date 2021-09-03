//
//  GCircle.swift
//  Graphism
//
//  Created by Emil Pedersen on 28/06/2020.
//

import Foundation

class GCircle: RectangularShape, PaintedShape, RotatableShape {
    var givenName: String?
    var typeKey: String { size.square ? "Circle" : "Ellipse" }
    
    let uuid = UUID()
    
    var position: Pos
    var positionZ: Int = 0
    var size: Pos
    var rotation: Rotation = 0
    var rotationCenter: Pos?
    
    var paint: AnyPaint
    var strokeStyle: StrokeWrapper?
    
    init(givenName: String? = nil, position: Pos, positionZ: Int = 0, size: Pos, rotation: Rotation = 0, paint: AnyPaint, strokeStyle: StrokeWrapper? = nil) {
        self.givenName = givenName
        self.position = position
        self.positionZ = positionZ
        self.size = size
        self.rotation = rotation
        self.paint = paint
        self.strokeStyle = strokeStyle
    }
    
    var stateDefinitions: String { "" }
    var stateConstructor: String {
        "Ellipse(\(givenName?.asLiteral ?? "")\(position.state) \(positionZ) \(size.state) \(rotation.state) \(paint.state)\(strokeStyle?.stateConstructor ?? ""))"
    }
    
    var type: GRPHType { SimpleType.Circle }
    
    func toSVG<T>(context: SVGExportContext, into out: inout T) where T : TextOutputStream {
        out.writeln(#"<ellipse name="\#(effectiveName)" cx="\#(center.x)" cy="\#(center.y)" rx="\#(size.x / 2)" ry="\#(size.y / 2)" fill="\#(strokeStyle == nil ? svgPaint : "none")" stroke="\#(strokeStyle != nil ? svgPaint : "none")"\#(strokeStyle?.svgStroke ?? "") transform="rotate(\#(rotation) \#(currentRotationCenter.x) \#(currentRotationCenter.y))"/>"#)
    }
}
