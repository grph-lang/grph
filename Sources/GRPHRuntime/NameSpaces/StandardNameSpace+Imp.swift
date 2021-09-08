//
//  StandardNameSpace.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation
import GRPHValues

extension StandardNameSpace: ImplementedNameSpace {
    
    func registerImplementations(reg: NativeFunctionRegistry) throws {
        registerConstructorLegacyFunction(reg: reg, type: SimpleType.color)
        registerConstructorLegacyFunction(reg: reg, type: SimpleType.linear)
        registerConstructorLegacyFunction(reg: reg, type: SimpleType.radial)
        registerConstructorLegacyFunction(reg: reg, type: SimpleType.font)
        reg.implement(function: exportedFunctions[named: "colorFromInt"]) { context, params in
            let value = params[0] as! Int
            return ColorPaint(integer: value, alpha: true)
        }
        // file manipulation functions removed
        reg.implement(function: exportedFunctions[named: "stringToInteger"]) { context, params in
            return GRPHOptional(Int(params[0] as! String))
        }
        reg.implement(function: exportedFunctions[named: "stringToFloat"]) { context, params in
            return GRPHOptional(Float(params[0] as! String))
        }
        reg.implement(function: exportedFunctions[named: "toString"]) { context, params in
            return params.map { $0 ?? "null" }.map(stringRepresentation).joined(separator: " ")
        }
        reg.implement(function: exportedFunctions[named: "concat"]) { context, params in
            return params.map { $0 ?? "null" }.map(stringRepresentation).joined()
        }
        reg.implement(function: exportedFunctions[named: "log"]) { context, params in
            let result = params.map { $0 ?? "null" }.map(stringRepresentation).joined(separator: " ")
            printout("Log: \(result)")
            return result
        }
        // getters for fields removed
        reg.implement(function: exportedFunctions[named: "getRotation"]) { context, params in
            guard let shape = params[0] as? RotatableShape else {
                throw GRPHRuntimeError(type: .typeMismatch, message: "Shape has no concept of rotation")
            }
            return shape.rotation
        }
        reg.implement(function: exportedFunctions[named: "getPosition"]) { context, params in
            guard let shape = params[0] as? PositionableShape else {
                throw GRPHRuntimeError(type: .typeMismatch, message: "Shape has no concept of position")
            }
            return shape.position
        }
        reg.implement(function: exportedFunctions[named: "getSize"]) { context, params in
            guard let shape = params[0] as? ResizableShape else {
                throw GRPHRuntimeError(type: .typeMismatch, message: "Shape has no concept of size")
            }
            return shape.size
        }
        reg.implement(function: exportedFunctions[named: "getCenterPoint"]) { context, params in
            guard let shape = params[0] as? RectangularShape else {
                throw GRPHRuntimeError(type: .typeMismatch, message: "Shape has no concept of center")
            }
            return shape.center
        }
        reg.implement(function: exportedFunctions[named: "getName"]) { context, params in
            return (params[0] as! GShape).effectiveName
        }
        reg.implement(function: exportedFunctions[named: "getPaint"]) { context, params in
            guard let shape = params[0] as? PaintedShape else {
                throw GRPHRuntimeError(type: .typeMismatch, message: "Shape has no concept of paint")
            }
            return shape.paint.unwrapped
        }
        reg.implement(function: exportedFunctions[named: "getStrokeWidth"]) { context, params in
            guard let shape = params[0] as? PaintedShape else {
                throw GRPHRuntimeError(type: .typeMismatch, message: "Shape has no concept of paint")
            }
            return (shape.strokeStyle ?? StrokeWrapper()).strokeWidth
        }
        reg.implement(function: exportedFunctions[named: "getStrokeType"]) { context, params in
            guard let shape = params[0] as? PaintedShape else {
                throw GRPHRuntimeError(type: .typeMismatch, message: "Shape has no concept of paint")
            }
            return (shape.strokeStyle ?? StrokeWrapper()).strokeType
        }
        reg.implement(function: exportedFunctions[named: "getStrokeDashArray"]) { context, params in
            guard let shape = params[0] as? PaintedShape else {
                throw GRPHRuntimeError(type: .typeMismatch, message: "Shape has no concept of paint")
            }
            return (shape.strokeStyle ?? StrokeWrapper()).strokeDashArray
        }
        reg.implement(function: exportedFunctions[named: "isFilled"]) { context, params in
            guard let shape = params[0] as? PaintedShape else {
                throw GRPHRuntimeError(type: .typeMismatch, message: "Shape has no concept of paint")
            }
            return shape.strokeStyle == nil
        }
        reg.implement(function: exportedFunctions[named: "getZPos"]) { context, params in
            return (params[0] as! GShape).positionZ
        }
        reg.implement(function: exportedFunctions[named: "getFont"]) { context, params in
            return (params[0] as! GText).font
        }
        reg.implement(function: exportedFunctions[named: "getPoint"]) { context, params in
            let shape = params[0] as! GPolygon
            let index = params[1] as! Int
            guard index < shape.points.count else {
                throw GRPHRuntimeError(type: .invalidArgument, message: "Index out of bounds")
            }
            return shape.points[index]
        }
        reg.implement(function: exportedFunctions[named: "getXForPos"]) { context, params in
            return (params[0] as! Pos).x
        }
        reg.implement(function: exportedFunctions[named: "getYForPos"]) { context, params in
            return (params[0] as! Pos).y
        }
        reg.implement(function: exportedFunctions[named: "integerToRotation"]) { context, params in
            return Rotation(value: params[0] as! Int)
        }
        reg.implement(function: exportedFunctions[named: "rotationToInteger"]) { context, params in
            return (params[0] as! Rotation).value
        }
        reg.implement(function: exportedFunctions[named: "getValueInArray"]) { context, params in
            let arr = params[0] as! GRPHArray
            let index = params[1] as! Int
            guard index < arr.count else {
                throw GRPHRuntimeError(type: .invalidArgument, message: "Index out of bounds")
            }
            return arr.wrapped[index]
        }
        reg.implement(function: exportedFunctions[named: "getArrayLength"]) { context, params in
            return (params[0] as! GRPHArray).count
        }
        reg.implement(function: exportedFunctions[named: "getShape"]) { context, params in
            let arr = context.runtime.image.shapes
            let index = params[0] as! Int
            guard index < arr.count else {
                throw GRPHRuntimeError(type: .invalidArgument, message: "Index out of bounds")
            }
            return arr[index]
        }
        // getShapeAt, intersects posAround, cloneShape etc missing TODO
        reg.implement(function: exportedFunctions[named: "getShapeNamed"]) { context, params in
            let name = params[0] as! String
            return GRPHOptional(context.runtime.image.shapes.first { $0.givenName == name })
        }
        reg.implement(function: exportedFunctions[named: "getNumberOfShapes"]) { context, params in
            return context.runtime.image.shapes.count
        }
        reg.implement(function: exportedFunctions[named: "createPos"]) { context, params in
            return Pos(x: params[0] as? Float ?? Float(params[0] as! Int), y: params[1] as? Float ?? Float(params[1] as! Int))
        }
        reg.implement(function: exportedFunctions[named: "clippedShape"]) { context, params in
            return GClip(shape: params[0] as! GShape, clip: params[1] as! GShape)
        }
        reg.implement(function: exportedFunctions[named: "isInGroup"]) { context, params in
            return (params[0] as! GGroup).shapes.contains(where: { $0.isEqual(to: params[1]!) })
        }
        reg.implement(function: exportedFunctions[named: "range"]) { context, params in
            let first = params[0] as! Int
            let last = params[1] as! Int
            let step = params.count == 2 ? 1 : abs(params[2] as! Int)
            guard step != 0 else {
                throw GRPHRuntimeError(type: .invalidArgument, message: "step cannot be 0")
            }
            let array = [Int](unsafeUninitializedCapacity: abs(first - last) / step + 1) { buffer, count in
                var i = first
                var index = 0
                while i <= last {
                    buffer[index] = i
                    i += step
                    index += 1
                }
                count = index
            }
            return GRPHArray(array, of: SimpleType.integer)
        }
        // == Migrated methods ==
        reg.implement(function: exportedFunctions[named: "validate"]) { context, params in
            let shape = params[0] as! GShape
            context.runtime.image.shapes.append(shape)
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(function: exportedFunctions[named: "validateAll"]) { context, params in
            let img = context.runtime.image
            for v in context.allVariables {
                if v.name != "back" && v.type.isInstance(of: SimpleType.shape) {
                    img.shapes.append(v.content as! GShape)
                }
            }
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(function: exportedFunctions[named: "unvalidate"]) { context, params in
            let shape = params[0] as! GShape
            context.runtime.image.shapes.removeAll { $0.isEqual(to: shape) }
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(function: exportedFunctions[named: "update"]) { context, params in
            context.runtime.image.willNeedRepaint()
            return GRPHVoid.void
        }
        reg.implement(function: exportedFunctions[named: "wait"]) { context, params in
            let result = context.runtime.image.destroySemaphore.wait(timeout: .now() + .milliseconds(params[0] as! Int))
            if result == .success {
                // The semaphore signaled. This means we were destroyed. We signal other threads that might wait too
                context.runtime.image.destroySemaphore.signal()
                // As GImage.destroyed is true, the runtime or the block will terminate for us
            }
            return GRPHVoid.void
        }
        reg.implement(function: exportedFunctions[named: "end"]) { context, params in
            context.runtime.image.destroy()
            throw GRPHExecutionTerminated()
        }
        // LEGACY
        reg.implement(function: exportedFunctions[named: "setHCentered"]) { context, params in
            let on = try typeCheck(value: params[0], as: AlignableShape.self)
            on.setHCentered(img: context.runtime.image)
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(function: exportedFunctions[named: "setLeftAligned"]) { context, params in
            let on = try typeCheck(value: params[0], as: AlignableShape.self)
            on.setLeftAligned(img: context.runtime.image)
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(function: exportedFunctions[named: "setRightAligned"]) { context, params in
            let on = try typeCheck(value: params[0], as: AlignableShape.self)
            on.setRightAligned(img: context.runtime.image)
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(function: exportedFunctions[named: "setVCentered"]) { context, params in
            let on = try typeCheck(value: params[0], as: AlignableShape.self)
            on.setVCentered(img: context.runtime.image)
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(function: exportedFunctions[named: "setTopAligned"]) { context, params in
            let on = try typeCheck(value: params[0], as: AlignableShape.self)
            on.setTopAligned(img: context.runtime.image)
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(function: exportedFunctions[named: "setBottomAligned"]) { context, params in
            let on = try typeCheck(value: params[0], as: AlignableShape.self)
            on.setBottomAligned(img: context.runtime.image)
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(method: exportedMethods[named: "rotate", inType: SimpleType.shape]) { context, on, params in
            let on = try typeCheck(value: on, as: RotatableShape.self)
            on.rotation = on.rotation + (params[0] as! Rotation)
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(method: exportedMethods[named: "setRotation", inType: SimpleType.shape]) { context, on, params in
            let on = try typeCheck(value: on, as: RotatableShape.self)
            on.rotation = params[0] as! Rotation
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(method: exportedMethods[named: "setRotationCenter", inType: SimpleType.shape]) { context, on, params in
            let on = try typeCheck(value: on, as: RotatableShape.self)
            on.rotationCenter = (params[0] as! GRPHOptional).content as? Pos
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(method: exportedMethods[named: "translate", inType: SimpleType.shape]) { context, on, params in
            let on = on as! GShape
            on.translate(by: params[0] as! Pos)
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(method: exportedMethods[named: "setPosition", inType: SimpleType.shape]) { context, on, params in
            let on = try typeCheck(value: on, as: PositionableShape.self)
            on.position = params[0] as! Pos
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        // ON SHAPES
        reg.implement(method: exportedMethods[named: "setHCentered", inType: SimpleType.shape]) { context, on, params in
            let on = try typeCheck(value: on, as: AlignableShape.self)
            on.setHCentered(img: context.runtime.image)
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(method: exportedMethods[named: "setLeftAligned", inType: SimpleType.shape]) { context, on, params in
            let on = try typeCheck(value: on, as: AlignableShape.self)
            on.setLeftAligned(img: context.runtime.image)
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(method: exportedMethods[named: "setRightAligned", inType: SimpleType.shape]) { context, on, params in
            let on = try typeCheck(value: on, as: AlignableShape.self)
            on.setRightAligned(img: context.runtime.image)
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(method: exportedMethods[named: "setVCentered", inType: SimpleType.shape]) { context, on, params in
            let on = try typeCheck(value: on, as: AlignableShape.self)
            on.setVCentered(img: context.runtime.image)
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(method: exportedMethods[named: "setTopAligned", inType: SimpleType.shape]) { context, on, params in
            let on = try typeCheck(value: on, as: AlignableShape.self)
            on.setTopAligned(img: context.runtime.image)
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(method: exportedMethods[named: "setBottomAligned", inType: SimpleType.shape]) { context, on, params in
            let on = try typeCheck(value: on, as: AlignableShape.self)
            on.setBottomAligned(img: context.runtime.image)
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        // TODO mirror
        reg.implement(method: exportedMethods[named: "grow", inType: SimpleType.shape]) { context, on, params in
            let on = try typeCheck(value: on, as: ResizableShape.self)
            on.size = on.size + (params[0] as! Pos)
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(method: exportedMethods[named: "setSize", inType: SimpleType.shape]) { context, on, params in
            let on = try typeCheck(value: on, as: ResizableShape.self)
            on.size = params[0] as! Pos
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(method: exportedMethods[named: "setName", inType: SimpleType.shape]) { context, on, params in
            let shape = on as! GShape
            shape.effectiveName = params[0] as! String
            if shape is GText {
                context.runtime.triggerAutorepaint()
            }
            return GRPHVoid.void
        }
        reg.implement(method: exportedMethods[named: "setPaint", inType: SimpleType.shape]) { context, on, params in
            let on = try typeCheck(value: on, as: PaintedShape.self)
            on.paint = AnyPaint.auto(params[0]!)
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(method: exportedMethods[named: "setStroke", inType: SimpleType.shape]) { context, on, params in
            let on = try typeCheck(value: on, as: PaintedShape.self)
            on.strokeStyle = StrokeWrapper(strokeWidth: params.count == 0 ? 5 : params[0] as! Float,
                                           strokeType: params.count <= 1 ? .elongated : params[1] as! Stroke,
                                           strokeDashArray: params.count <= 2 ? GRPHArray(of: SimpleType.float) : params[2] as! GRPHArray)
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(method: exportedMethods[named: "filling", inType: SimpleType.shape]) { context, on, params in
            let on = try typeCheck(value: on, as: PaintedShape.self)
            let val = params[0] as! Bool
            if val != (on.strokeStyle == nil) {
                if val {
                    on.strokeStyle = nil
                } else {
                    on.strokeStyle = StrokeWrapper()
                }
            }
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(method: exportedMethods[named: "setZPos", inType: SimpleType.shape]) { context, on, params in
            let shape = on as! GShape
            shape.positionZ = params[0] as! Int
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        // Polygons
        reg.implement(method: exportedMethods[named: "addPoint", inType: SimpleType.Polygon]) { context, on, params in
            let shape = on as! GPolygon
            shape.points.append(params[0] as! Pos)
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(method: exportedMethods[named: "setPoint", inType: SimpleType.Polygon]) { context, on, params in
            let shape = on as! GPolygon
            shape.points[params[0] as! Int] = params[1] as! Pos
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(method: exportedMethods[named: "setPoints", inType: SimpleType.Polygon]) { context, on, params in
            let shape = on as! GPolygon
            shape.points = params.map { $0 as! Pos }
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        // Paths
        reg.implement(method: exportedMethods[named: "moveTo", inType: SimpleType.Path]) { context, on, params in
            let shape = on as! GPath
            shape.actions.append(.moveTo)
            shape.points.append(params[0] as! Pos)
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(method: exportedMethods[named: "lineTo", inType: SimpleType.Path]) { context, on, params in
            let shape = on as! GPath
            shape.actions.append(.lineTo)
            shape.points.append(params[0] as! Pos)
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(method: exportedMethods[named: "quadTo", inType: SimpleType.Path]) { context, on, params in
            let shape = on as! GPath
            shape.actions.append(.quadTo)
            shape.points.append(params[0] as! Pos)
            shape.points.append(params[1] as! Pos)
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(method: exportedMethods[named: "cubicTo", inType: SimpleType.Path]) { context, on, params in
            let shape = on as! GPath
            shape.actions.append(.cubicTo)
            shape.points.append(params[0] as! Pos)
            shape.points.append(params[1] as! Pos)
            shape.points.append(params[2] as! Pos)
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(method: exportedMethods[named: "closePath", inType: SimpleType.Path]) { context, on, params in
            let shape = on as! GPath
            shape.actions.append(.closePath)
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(method: exportedMethods[named: "addToGroup", inType: SimpleType.Group]) { context, on, params in
            let shape = on as! GGroup
            shape.shapes.append(params[0] as! GShape)
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        reg.implement(method: exportedMethods[named: "removeFromGroup", inType: SimpleType.Group]) { context, on, params in
            let shape = on as! GGroup
            let uuid = (params[0] as! GShape).uuid
            shape.shapes.removeAll { $0.uuid == uuid }
            context.runtime.triggerAutorepaint()
            return GRPHVoid.void
        }
        
        // This one is generic, defined in the type
        reg.implement(methodWithSignature: "{T} {T}.copy[]") { context, array, params in
            let array = array as! GRPHArray
            return GRPHArray(array.wrapped, of: array.content)
        }
    }
    
    func typeCheck<T>(value: GRPHValue?, as: T.Type) throws -> T {
        if let value = value as? T {
            return value
        } else {
            throw GRPHRuntimeError(type: .typeMismatch, message: "A \(value?.type.string ?? "<not provided>") is not a \(T.self)")
        }
    }
    
    func registerConstructorLegacyFunction(reg: NativeFunctionRegistry, type: GRPHType) {
        let base = type.constructor!
        let imp = reg.implementation(for: base)
        reg.implement(function: constructorLegacyFunction(type: type)) { ctx, args in
            imp(type, ctx, args)
        }
    }
    
    func stringRepresentation(val: GRPHValue) -> String {
        if let val = val as? CustomStringConvertible {
            return val.description
        } else if let val = val as? StatefulValue {
            return val.state
        }
        return "<@\(val.type.string)>"
    }
}
