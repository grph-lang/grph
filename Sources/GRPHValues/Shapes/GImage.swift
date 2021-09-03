//
//  GImage.swift
//  Graphism
//
//  Created by Emil Pedersen on 08/07/2020.
//

import Foundation

public class GImage: GGroup, PaintedShape, ResizableShape {
    public var size: Pos
    public var paint: AnyPaint
    
    public var strokeStyle: StrokeWrapper? // unused
    
    public var destroySemaphore = DispatchSemaphore(value: 0)
    private(set) public var destroyed = false
    
    public var delegate: () -> Void
    
    public init(size: Pos = Pos(x: 640, y: 480),
         background: AnyPaint = AnyPaint.color(ColorPaint.components(red: 0, green: 0, blue: 0, alpha: 0)),
         delegate: @escaping () -> Void) {
        self.size = size
        self.paint = background
        self.delegate = delegate
        super.init(givenName: nil)
    }
    
    override public var typeKey: String {
        "Background"
    }
    
    override public var type: GRPHType {
        SimpleType.Background
    }
    
    override public var stateDefinitions: String {
        "" // never called
    }
    
    override public var stateConstructor: String {
        "Background(\(size.state) \(paint.state))"
    }
    
    public func willNeedRepaint() {
        delegate()
    }
    
    /// Called by the view when the document is closed
    public func destroy() {
        destroyed = true
        destroySemaphore.signal()
    }
    
    override public func collectSVGDefinitions<T>(context: SVGExportContext, into out: inout T) where T : TextOutputStream {
        self.collectSVGPaintDefinitions(context: context, into: &out)
        super.collectSVGDefinitions(context: context, into: &out)
    }
    
    override public func toSVG<T: TextOutputStream>(context: SVGExportContext, into out: inout T) {
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
