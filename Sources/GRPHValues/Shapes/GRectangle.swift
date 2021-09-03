//
//  GRectangle.swift
//  Graphism
//
//  Created by Emil Pedersen on 28/06/2020.
//

import Foundation

public class GRectangle: RectangularShape, PaintedShape, RotatableShape {
    
    public var givenName: String?
    public var typeKey: String { size.square ? "Square" : "Rectangle" }
    
    public let uuid = UUID()
    
    public var position: Pos
    public var positionZ: Int = 0
    public var size: Pos
    public var rotation: Rotation = 0
    public var rotationCenter: Pos?
    
    public var paint: AnyPaint
    public var strokeStyle: StrokeWrapper?
    
    public init(givenName: String? = nil, position: Pos, positionZ: Int = 0, size: Pos, rotation: Rotation = 0, paint: AnyPaint, strokeStyle: StrokeWrapper? = nil) {
        self.givenName = givenName
        self.position = position
        self.positionZ = positionZ
        self.size = size
        self.rotation = rotation
        self.paint = paint
        self.strokeStyle = strokeStyle
    }
    
    public var stateDefinitions: String { "" }
    public var stateConstructor: String {
        "Rectangle(\(givenName?.asLiteral ?? "")\(position.state) \(positionZ) \(size.state) \(rotation.state) \(paint.state)\(strokeStyle?.stateConstructor ?? ""))"
    }
    
    public var type: GRPHType { SimpleType.Rectangle }
    
    public func toSVG<T>(context: SVGExportContext, into out: inout T) where T : TextOutputStream {
        out.writeln(#"<rect name="\#(effectiveName)" x="\#(position.x)" y="\#(position.y)" width="\#(size.x)" height="\#(size.y)" fill="\#(strokeStyle == nil ? svgPaint : "none")" stroke="\#(strokeStyle != nil ? svgPaint : "none")"\#(strokeStyle?.svgStroke ?? "") transform="rotate(\#(rotation) \#(currentRotationCenter.x) \#(currentRotationCenter.y))"/>"#)
    }
}
