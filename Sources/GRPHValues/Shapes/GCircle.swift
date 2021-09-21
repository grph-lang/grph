//
//  GCircle.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 28/06/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public class GCircle: RectangularShape, PaintedShape, RotatableShape {
    public var givenName: String?
    public var typeKey: String { size.square ? "Circle" : "Ellipse" }
    
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
        "Ellipse(\(givenName?.asLiteral ?? "")\(position.state) \(positionZ) \(size.state) \(rotation.state) \(paint.state)\(strokeStyle?.stateConstructor ?? ""))"
    }
    
    public var type: GRPHType { SimpleType.Circle }
    
    public func toSVG<T>(context: SVGExportContext, into out: inout T) where T : TextOutputStream {
        out.writeln(#"<ellipse name="\#(effectiveName)" cx="\#(center.x)" cy="\#(center.y)" rx="\#(size.x / 2)" ry="\#(size.y / 2)" fill="\#(strokeStyle == nil ? svgPaint : "none")" stroke="\#(strokeStyle != nil ? svgPaint : "none")"\#(strokeStyle?.svgStroke ?? "") transform="rotate(\#(rotation) \#(currentRotationCenter.x) \#(currentRotationCenter.y))"/>"#)
    }
}
