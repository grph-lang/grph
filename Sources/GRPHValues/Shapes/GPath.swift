//
//  GPath.swift
//  Graphism
//
//  Created by Emil Pedersen on 28/06/2020.
//

import Foundation

class GPath: PaintedShape, RotatableShape {
    var givenName: String?
    var typeKey: String { "Path" }
    
    let uuid = UUID()
    
    var points: [Pos] = []
    var actions: [PathActions] = []
    var positionZ: Int = 0
    
    var paint: AnyPaint
    var strokeStyle: StrokeWrapper?
    
    var rotation: Rotation = 0
    var rotationCenter: Pos?
    
    init(givenName: String? = nil, points: [Pos] = [], actions: [PathActions] = [], positionZ: Int = 0, rotation: Rotation = 0, paint: AnyPaint, strokeStyle: StrokeWrapper? = nil) {
        self.givenName = givenName
        self.points = points
        self.actions = actions
        self.positionZ = positionZ
        self.paint = paint
        self.strokeStyle = strokeStyle
        self.rotation = rotation
    }
    
    var stateDefinitions: String {
        let uniqueVarName = String(uuid.hashValue, radix: 36).dropFirst() // first might be a -
        var str = "Path path\(uniqueVarName) = Path(\(givenName?.asLiteral ?? "")\(positionZ) \(paint.state)\(strokeStyle?.stateConstructor ?? ""))\n"
        var i = 0
        for action in actions {
            switch action {
            case .moveTo:
                str += "moveTo path\(uniqueVarName): \(points[i].state)\n"
                i += 1
            case .lineTo:
                str += "lineTo path\(uniqueVarName): \(points[i].state)\n"
                i += 1
            case .quadTo:
                str += "quadTo path\(uniqueVarName): \(points[i].state) \(points[i + 1].state)\n"
                i += 2
            case .cubicTo:
                str += "cubicTo path\(uniqueVarName): \(points[i].state) \(points[i + 1].state) \(points[i + 2].state)\n"
                i += 3
            case .closePath:
                str += "closePath path\(uniqueVarName):\n"
            }
        }
        return str
    }
    
    var stateConstructor: String {
        "path\(String(uuid.hashValue, radix: 36).dropFirst())"
    }
    
    var type: GRPHType { SimpleType.Path }
    
    func translate(by diff: Pos) {
        points = points.map { $0 + diff }
    }
    
    func toSVG<T>(context: SVGExportContext, into out: inout T) where T : TextOutputStream {
        out.writeln(#"<path name="\#(effectiveName)" fill="\#(strokeStyle == nil ? svgPaint : "none")" stroke="\#(strokeStyle != nil ? svgPaint : "none")"\#(strokeStyle?.svgStroke ?? "") transform="rotate(\#(rotation) \#(rotationCenter?.x.description ?? "") \#(rotationCenter?.y.description ?? ""))" d="\#(svgPath)"/>"#)
    }
    
    var svgPath: String {
        var str = ""
        var i = 0
        for action in actions {
            switch action {
            case .moveTo:
                str += "M \(points[i].x) \(points[i].y) "
                i += 1
            case .lineTo:
                str += "L \(points[i].x) \(points[i].y) "
                i += 1
            case .quadTo:
                str += "Q \(points[i].x) \(points[i].y), \(points[i + 1].x) \(points[i + 1].y) "
                i += 2
            case .cubicTo:
                str += "C \(points[i].x) \(points[i].y), \(points[i + 1].x) \(points[i + 1].y), \(points[i + 2].x) \(points[i + 2].y) "
                i += 3
            case .closePath:
                str += "Z "
            }
        }
        return str
    }
}

enum PathActions {
    case moveTo
    case lineTo
    case quadTo
    case cubicTo
    case closePath
}
