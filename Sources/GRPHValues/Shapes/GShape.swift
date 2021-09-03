//
//  GShape.swift
//  Graphism
//
//  Created by Emil Pedersen on 28/06/2020.
//

import Foundation

protocol GShape: GRPHValue, AnyObject {
    var uuid: UUID { get }
    
    var positionZ: Int { get set }
    var givenName: String? { get set }
    var typeKey: String { get }
    
    var stateDefinitions: String { get }
    var stateConstructor: String { get }
    
    func translate(by diff: Pos)
    
    func collectSVGDefinitions<T: TextOutputStream>(context: SVGExportContext, into out: inout T)
    func toSVG<T: TextOutputStream>(context: SVGExportContext, into out: inout T)
}

protocol PositionableShape: GShape {
    var position: Pos { get set }
}

protocol PaintedShape: GShape {
    var paint: AnyPaint { get set }
    var strokeStyle: StrokeWrapper? { get set }
}

protocol RotatableShape: GShape {
    var rotation: Rotation { get set }
    var rotationCenter: Pos? { get set }
}

protocol AlignableShape: GShape {
    func setHCentered(img: GImage)
    func setLeftAligned(img: GImage)
    func setRightAligned(img: GImage)
    
    func setVCentered(img: GImage)
    func setTopAligned(img: GImage)
    func setBottomAligned(img: GImage)
}

protocol ResizableShape: GShape {
    var size: Pos { get set }
}

protocol RectangularShape: PositionableShape, AlignableShape, ResizableShape {}

// Extensions

extension GShape {
    var effectiveName: String {
        get {
            givenName ?? NSLocalizedString(typeKey, comment: "") // will not get localized on CLI version
        }
        set {
            givenName = newValue
        }
    }
    
    func isEqual(to other: GRPHValue) -> Bool {
        if let shape = other as? GShape {
            return self.uuid == shape.uuid
        }
        return false
    }
    
    func collectSVGDefinitions<T: TextOutputStream>(context: SVGExportContext, into out: inout T) {}
}

extension PaintedShape {
    func collectSVGDefinitions<T: TextOutputStream>(context: SVGExportContext, into out: inout T) {
        collectSVGPaintDefinitions(context: context, into: &out)
    }
    func collectSVGPaintDefinitions<T: TextOutputStream>(context: SVGExportContext, into out: inout T) {
        switch paint {
        case .color(_):
            break
        case .linear(let linear):
            out.writeln("<linearGradient id=\"grad\(uuid)\" x1=\"\(linear.direction.reverse.pointingTowards.x * 100)%\" y1=\"\(linear.direction.reverse.pointingTowards.y * 100)%\" x2=\"\(linear.direction.pointingTowards.x * 100)%\" y2=\"\(linear.direction.pointingTowards.y * 100)%\">")
            out.writeln("<stop offset=\"0%\" style=\"stop-color:\(linear.from.svgColor)\" />")
            out.writeln("<stop offset=\"100%\" style=\"stop-color:\(linear.to.svgColor)\" />")
            out.writeln("</linearGradient>")
        case .radial(let radial):
            out.writeln("<radialGradient id=\"grad\(uuid)\" cx=\"\(radial.center.x * 100)%\" cy=\"\(radial.center.y * 100)%\" r=\"\(radial.radius * 100)%\">")
            out.writeln("<stop offset=\"0%\" style=\"stop-color:\(radial.centerColor.svgColor)\" />")
            out.writeln("<stop offset=\"100%\" style=\"stop-color:\(radial.externalColor.svgColor)\" />")
            out.writeln("</radialGradient>")
        }
    }
    var svgPaint: String {
        switch paint {
        case .color(let color):
            return color.svgColor
        case .linear(_), .radial(_):
            return "url(#grad\(uuid))"
        }
    }
}

extension PositionableShape {
    func translate(by diff: Pos) {
        position += diff
    }
}

extension RectangularShape {
    var center: Pos {
        get {
            Pos(x: position.x + (size.x / 2), y: position.y + (size.y / 2))
        }
        set {
            position = Pos(x: newValue.x - (size.x / 2), y: newValue.y - (size.y / 2))
        }
    }
    
    func setHCentered(img: GImage) {
        position.x = img.size.x / 2 - size.x / 2
    }
    
    func setLeftAligned(img: GImage) {
        position.x = 0
    }
    
    func setRightAligned(img: GImage) {
        position.x = img.size.x - size.x
    }
    
    func setVCentered(img: GImage) {
        position.y = img.size.y / 2 - size.y / 2
    }
    
    func setTopAligned(img: GImage) {
        position.y = 0
    }
    
    func setBottomAligned(img: GImage) {
        position.y = img.size.y - size.y
    }
}

extension RectangularShape where Self: RotatableShape {
    var currentRotationCenter: Pos {
        rotationCenter ?? center
    }
}
