//
//  GClip.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 28/06/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public class GClip: GShape {
    
    public var givenName: String?
    public var typeKey: String { "Clip" }
    
    public let uuid = UUID()
    
    public var positionZ: Int = 0
    
    public var shape: GShape
    public var clip: GShape
    
    public init(shape: GShape, clip: GShape) {
        self.shape = shape
        self.clip = clip
    }
    
    public var stateDefinitions: String {
        shape.stateDefinitions + clip.stateDefinitions
    }
    
    public var stateConstructor: String {
        "clippedShape[\(shape.stateConstructor) \(clip.stateConstructor)]"
    }
    
    public var type: GRPHType { SimpleType.shape }
    
    public func translate(by diff: Pos) {
        shape.translate(by: diff)
        clip.translate(by: diff)
    }
    
    public func collectSVGDefinitions<T>(context: SVGExportContext, into out: inout T) where T : TextOutputStream {
        shape.collectSVGDefinitions(context: context, into: &out)
        out.writeln("<clipPath id=\"clip\(uuid)\">")
        clip.toSVG(context: context, into: &out)
        out.writeln("</clipPath>")
    }
    
    public func toSVG<T>(context: SVGExportContext, into out: inout T) where T : TextOutputStream {
        out.writeln(#"<g name="\#(effectiveName)" clip-path="url(#clip\#(uuid))">"#)
        shape.toSVG(context: context, into: &out)
        out.writeln("</g>")
    }
}
