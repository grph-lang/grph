//
//  GPolygon.swift
//  Graphism
//
//  Created by Emil Pedersen on 28/06/2020.
//

import Foundation

class GPolygon: PaintedShape, RotatableShape {
    var givenName: String?
    var typeKey: String { "Polygon" }
    
    let uuid = UUID()
    
    var points: [Pos] = []
    var positionZ: Int = 0
    
    var paint: AnyPaint
    var strokeStyle: StrokeWrapper?
    
    var rotation: Rotation = 0
    var rotationCenter: Pos?
    
    init(givenName: String? = nil, points: [Pos] = [], positionZ: Int = 0, paint: AnyPaint, strokeStyle: StrokeWrapper? = nil) {
        self.givenName = givenName
        self.points = points
        self.positionZ = positionZ
        self.paint = paint
        self.strokeStyle = strokeStyle
    }
    
    var stateDefinitions: String { "" }
    
    var stateConstructor: String {
        var state = "Polygon(\(givenName?.asLiteral ?? "")\(positionZ) \(paint.state)\(strokeStyle?.stateConstructor ?? "")"
        for point in points {
            state += " \(point.state)"
        }
        return state + ")"
    }
    
    var type: GRPHType { SimpleType.Polygon }
    
    func translate(by diff: Pos) {
        points = points.map { $0 + diff }
    }
    
    func toSVG<T>(context: SVGExportContext, into out: inout T) where T : TextOutputStream {
        out.writeln(#"<polygon name="\#(effectiveName)" points="\#(points.map { $0.state }.joined(separator: " "))" fill="\#(strokeStyle == nil ? svgPaint : "none")" stroke="\#(strokeStyle != nil ? svgPaint : "none")"\#(strokeStyle?.svgStroke ?? "") transform="rotate(\#(rotation) \#(currentRotationCenter.x) \#(currentRotationCenter.y))"/>"#)
    }
}

extension GPolygon: AlignableShape {
    func setHCentered(img: GImage) {
        if let min = points.min(by: { $0.x < $1.x }),
           let max = points.max(by: { $0.x < $1.x }) {
            translate(by: Pos(x: (img.size.x - max.x - min.x) / 2, y: 0))
        }
    }
    
    func setLeftAligned(img: GImage) {
        if let min = points.min(by: { $0.x < $1.x }) {
            translate(by: Pos(x: -min.x, y: 0))
        }
    }
    
    func setRightAligned(img: GImage) {
        if let max = points.max(by: { $0.x < $1.x }) {
            translate(by: Pos(x: img.size.x - max.x, y: 0))
        }
    }
    
    func setVCentered(img: GImage) {
        if let min = points.min(by: { $0.y < $1.y }),
           let max = points.max(by: { $0.y < $1.y }) {
            translate(by: Pos(x: 0, y: (img.size.y - max.y - min.y) / 2))
        }
    }
    
    func setTopAligned(img: GImage) {
        if let min = points.min(by: { $0.y < $1.y }) {
            translate(by: Pos(x: 0, y: -min.y))
        }
    }
    
    func setBottomAligned(img: GImage) {
        if let max = points.max(by: { $0.y < $1.y }) {
            translate(by: Pos(x: 0, y: img.size.y - max.y))
        }
    }
    
    var center: Pos {
        if let minX = points.min(by: { $0.x < $1.x })?.x,
           let maxX = points.max(by: { $0.x < $1.x })?.x,
           let minY = points.min(by: { $0.y < $1.y })?.y,
           let maxY = points.max(by: { $0.y < $1.y })?.y {
            return Pos(x: (maxX + minX) / 2, y: (maxY + minY) / 2)
        }
        return Pos(x: 0, y: 0)
    }
    
    var currentRotationCenter: Pos {
        rotationCenter ?? center
    }
}
