//
//  GClip.swift
//  Graphism
//
//  Created by Emil Pedersen on 28/06/2020.
//

import Foundation

class GClip: GShape {
    
    var givenName: String?
    var typeKey: String { "Clip" }
    
    let uuid = UUID()
    
    var positionZ: Int = 0
    
    var shape: GShape
    var clip: GShape
    
    init(shape: GShape, clip: GShape) {
        self.shape = shape
        self.clip = clip
    }
    
    var stateDefinitions: String {
        shape.stateDefinitions + clip.stateDefinitions
    }
    
    var stateConstructor: String {
        "clippedShape[\(shape.stateConstructor) \(clip.stateConstructor)]"
    }
    
    var type: GRPHType { SimpleType.shape }
    
    func translate(by diff: Pos) {
        shape.translate(by: diff)
        clip.translate(by: diff)
    }
    
    func collectSVGDefinitions<T>(context: SVGExportContext, into out: inout T) where T : TextOutputStream {
        shape.collectSVGDefinitions(context: context, into: &out)
        out.writeln("<clipPath id=\"clip\(uuid)\">")
        clip.toSVG(context: context, into: &out)
        out.writeln("</clipPath>")
    }
    
    func toSVG<T>(context: SVGExportContext, into out: inout T) where T : TextOutputStream {
        out.writeln(#"<g name="\#(effectiveName)" clip-path="url(#clip\#(uuid))">"#)
        shape.toSVG(context: context, into: &out)
        out.writeln("</g>")
    }
}
