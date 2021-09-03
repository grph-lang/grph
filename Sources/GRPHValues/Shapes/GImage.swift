//
//  GImage.swift
//  Graphism
//
//  Created by Emil Pedersen on 08/07/2020.
//

import Foundation

class GImage: GGroup, PaintedShape, ResizableShape {
    var size: Pos
    var paint: AnyPaint
    
    var strokeStyle: StrokeWrapper? // unused
    
    var destroySemaphore = DispatchSemaphore(value: 0)
    private(set) var destroyed = false
    
    var delegate: () -> Void
    
    init(size: Pos = Pos(x: 640, y: 480),
         background: AnyPaint = AnyPaint.color(ColorPaint.components(red: 0, green: 0, blue: 0, alpha: 0)),
         delegate: @escaping () -> Void) {
        self.size = size
        self.paint = background
        self.delegate = delegate
        super.init(givenName: nil)
    }
    
    override var typeKey: String {
        "Background"
    }
    
    override var type: GRPHType {
        SimpleType.Background
    }
    
    override var stateDefinitions: String {
        "" // never called
    }
    
    override var stateConstructor: String {
        "Background(\(size.state) \(paint.state))"
    }
    
    func willNeedRepaint() {
        delegate()
    }
    
    /// Called by the view when the document is closed
    func destroy() {
        destroyed = true
        destroySemaphore.signal()
    }
    
    override func collectSVGDefinitions<T>(context: SVGExportContext, into out: inout T) where T : TextOutputStream {
        self.collectSVGPaintDefinitions(context: context, into: &out)
        super.collectSVGDefinitions(context: context, into: &out)
    }
    
    override func toSVG<T: TextOutputStream>(context: SVGExportContext, into out: inout T) {
        out.writeln("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>")
        out.writeln("<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\" width=\"\(size.x)\" height=\"\(size.y)\" xmlns:xlink=\"http://www.w3.org/1999/xlink\">")
        
        out.writeln("<defs>")
        self.collectSVGDefinitions(context: context, into: &out)
        out.writeln("</defs>")
        
        out.writeln("<rect x=\"0\" y=\"0\" width=\"\(size.x)\" height=\"\(size.y)\" fill=\"\(svgPaint)\"/>")
        shapes.sorted { $0.positionZ < $1.positionZ }.forEach { $0.toSVG(context: context, into: &out) }
        
        out.writeln("</svg>")
    }
}
