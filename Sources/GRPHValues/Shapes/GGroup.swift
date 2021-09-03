//
//  GGroup.swift
//  Graphism
//
//  Created by Emil Pedersen on 08/07/2020.
//

import Foundation

class GGroup: GShape, RotatableShape {
    // rotation
    let uuid = UUID()
    
    var typeKey: String {
        "Group"
    }
    
    var givenName: String?
    var positionZ: Int = 0
    var shapes: [GShape] = []
    
    var rotation: Rotation = 0
    var rotationCenter: Pos?
    
    init(givenName: String?, positionZ: Int = 0, rotation: Rotation = 0, shapes: [GShape] = []) {
        self.givenName = givenName
        self.positionZ = positionZ
        self.shapes = shapes
        self.rotation = rotation
    }
    
    var stateDefinitions: String {
        shapes.map { $0.stateDefinitions }.joined()
    }
    
    var stateConstructor: String {
        "Group(\(givenName?.asLiteral ?? "")\(positionZ) \(shapes.map { $0.stateConstructor }.joined(separator: " ")))"
    }
    
    var type: GRPHType {
        SimpleType.Group
    }
    
    func translate(by diff: Pos) {
        shapes.forEach { $0.translate(by: diff) }
    }
    
    func collectSVGDefinitions<T>(context: SVGExportContext, into out: inout T) where T : TextOutputStream {
        shapes.forEach { $0.collectSVGDefinitions(context: context, into: &out) }
    }
    
    func toSVG<T>(context: SVGExportContext, into out: inout T) where T : TextOutputStream {
        out.writeln(#"<g name="\#(effectiveName)" transform="rotate(\#(rotation) \#(rotationCenter?.x.description ?? "") \#(rotationCenter?.y.description ?? ""))">"#)
        shapes.sorted { $0.positionZ < $1.positionZ }.forEach { $0.toSVG(context: context, into: &out) }
        out.writeln("</g>")
    }
}
