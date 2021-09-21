//
//  GGroup.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 08/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public class GGroup: GShape, RotatableShape {
    // rotation
    public let uuid = UUID()
    
    public var typeKey: String {
        "Group"
    }
    
    public var givenName: String?
    public var positionZ: Int = 0
    public var shapes: [GShape] = []
    
    public var rotation: Rotation = 0
    public var rotationCenter: Pos?
    
    public init(givenName: String?, positionZ: Int = 0, rotation: Rotation = 0, shapes: [GShape] = []) {
        self.givenName = givenName
        self.positionZ = positionZ
        self.shapes = shapes
        self.rotation = rotation
    }
    
    public var stateDefinitions: String {
        shapes.map { $0.stateDefinitions }.joined()
    }
    
    public var stateConstructor: String {
        "Group(\(givenName?.asLiteral ?? "")\(positionZ) \(shapes.map { $0.stateConstructor }.joined(separator: " ")))"
    }
    
    public var type: GRPHType {
        SimpleType.Group
    }
    
    public func translate(by diff: Pos) {
        shapes.forEach { $0.translate(by: diff) }
    }
    
    public func collectSVGDefinitions<T>(context: SVGExportContext, into out: inout T) where T : TextOutputStream {
        shapes.forEach { $0.collectSVGDefinitions(context: context, into: &out) }
    }
    
    public func toSVG<T>(context: SVGExportContext, into out: inout T) where T : TextOutputStream {
        out.writeln(#"<g name="\#(effectiveName)" transform="rotate(\#(rotation) \#(rotationCenter?.x.description ?? "") \#(rotationCenter?.y.description ?? ""))">"#)
        shapes.sorted { $0.positionZ < $1.positionZ }.forEach { $0.toSVG(context: context, into: &out) }
        out.writeln("</g>")
    }
}
