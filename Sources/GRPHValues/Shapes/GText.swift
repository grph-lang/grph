//
//  GText.swift
//  Graphism
//
//  Created by Emil Pedersen on 18/07/2020.
//

import Foundation

class GText: PaintedShape, PositionableShape, RotatableShape {
    
    var givenName: String?
    var typeKey: String { "Text" }
    
    let uuid = UUID()
    
    var paint: AnyPaint
    var strokeStyle: StrokeWrapper? = nil
    
    var font: JFont
    
    var position: Pos
    var positionZ: Int
    
    var rotation: Rotation
    var rotationCenter: Pos?
    
    init(givenName: String? = nil, position: Pos, positionZ: Int = 0, font: JFont, rotation: Rotation = 0, paint: AnyPaint) {
        self.givenName = givenName
        self.position = position
        self.positionZ = positionZ
        self.font = font
        self.rotation = rotation
        self.paint = paint
    }
    
    var stateDefinitions: String { "" }
    var stateConstructor: String {
        "Text(\(effectiveName.asLiteral)\(position.state) \(positionZ) \(font.state) \(paint.state))"
    }
    
    var type: GRPHType { SimpleType.Text }
    
    func toSVG<T>(context: SVGExportContext, into out: inout T) where T : TextOutputStream {
        out.writeln(#"<text x="\#(position.x)" y="\#(position.y)" fill="\#(svgPaint)" transform="rotate(\#(rotation) \#(rotationCenter?.x.description ?? "") \#(rotationCenter?.y.description ?? ""))" font-family="\#(font.name ?? "")" font-size="\#(font.size)" font-style="\#(font.italic ? "italic" : "normal")" font-weight="\#(font.bold ? "bold" : "normal")">\#(effectiveName)</text>"#)
    }
}
