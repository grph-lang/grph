//
//  GText.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 18/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public class GText: PaintedShape, PositionableShape, RotatableShape {
    
    public var givenName: String?
    public var typeKey: String { "Text" }
    
    public let uuid = UUID()
    
    public var paint: AnyPaint
    public var strokeStyle: StrokeWrapper? = nil
    
    public var font: JFont
    
    public var position: Pos
    public var positionZ: Int
    
    public var rotation: Rotation
    public var rotationCenter: Pos?
    
    public init(givenName: String? = nil, position: Pos, positionZ: Int = 0, font: JFont, rotation: Rotation = 0, paint: AnyPaint) {
        self.givenName = givenName
        self.position = position
        self.positionZ = positionZ
        self.font = font
        self.rotation = rotation
        self.paint = paint
    }
    
    public var stateDefinitions: String { "" }
    public var stateConstructor: String {
        "Text(\(effectiveName.asLiteral)\(position.state) \(positionZ) \(font.state) \(paint.state))"
    }
    
    public var type: GRPHType { SimpleType.Text }
    
    public func toSVG<T>(context: SVGExportContext, into out: inout T) where T : TextOutputStream {
        out.writeln(#"<text x="\#(position.x)" y="\#(position.y)" fill="\#(svgPaint)" transform="rotate(\#(rotation) \#(rotationCenter?.x.description ?? "") \#(rotationCenter?.y.description ?? ""))" font-family="\#(font.name ?? "")" font-size="\#(font.size)" font-style="\#(font.italic ? "italic" : "normal")" font-weight="\#(font.bold ? "bold" : "normal")">\#(effectiveName)</text>"#)
    }
}
