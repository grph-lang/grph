//
//  Constructor+Imp.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/09/2021.
//

import Foundation
import GRPHValues

extension Constructor {
    /// These are the first implementations to be registered
    static func registerImplementations(reg: NativeFunctionRegistry) throws {
        
        // Simple Types
        
        reg.implement(constructor: SimpleType.void.constructor!) { type, context, values in
            return GRPHVoid.void
        }
        reg.implement(constructor: SimpleType.rotation.constructor!) { type, context, values in
            return Rotation(value: values[0] as! Int)
        }
        reg.implement(constructor: SimpleType.pos.constructor!) { type, context, values in
            return Pos(x: values[0] as? Float ?? Float(values[0] as! Int), y: values[1] as? Float ?? Float(values[1] as! Int))
        }
        reg.implement(constructor: SimpleType.color.constructor!) { type, context, values in
            return ColorPaint.components(red: Float(values[0] as! Int) / 255, green: Float(values[1] as! Int) / 255, blue: Float(values[2] as! Int) / 255, alpha: values.count == 4 ? values[3] as! Float : 1)
        }
        reg.implement(constructor: SimpleType.linear.constructor!) { type, context, values in
            return LinearPaint(from: values[0] as! ColorPaint, direction: values[1] as! Direction, to: values[2] as! ColorPaint)
        }
        reg.implement(constructor: SimpleType.radial.constructor!) { type, context, values in
            return RadialPaint(centerColor: values[0] as! ColorPaint, center: values[1] as? Pos ?? Pos(x: 0.5, y: 0.5), externalColor: values[2] as! ColorPaint, radius: values[3] as! Float)
        }
        reg.implement(constructor: SimpleType.font.constructor!) { type, context, values in
            return JFont(name: values[0] as? String, size: values[1] as! Int, weight: values.count == 3 ? values[2] as! Int : JFont.plain)
        }
        reg.implement(constructor: SimpleType.Rectangle.constructor!) { type, context, values in
            return GRectangle(givenName: values[0] as? String,
                              position: values[1] as! Pos,
                              positionZ: values[2] as? Int ?? 0,
                              size: values[3] as! Pos,
                              rotation: values[4] as? Rotation ?? 0,
                              paint: AnyPaint.auto(values[5]!),
                              strokeStyle: values.count == 6 ? nil : StrokeWrapper(strokeWidth: values[6] as? Float ?? 5, strokeType: values[safe: 7] as? Stroke ?? .elongated, strokeDashArray: values[safe: 8] as? GRPHArray ?? GRPHArray([], of: SimpleType.float)))
        }
        reg.implement(constructor: SimpleType.Circle.constructor!) { type, context, values in
            return GCircle(givenName: values[0] as? String,
                           position: values[1] as! Pos,
                           positionZ: values[2] as? Int ?? 0,
                           size: values[3] as! Pos,
                           rotation: values[4] as? Rotation ?? 0,
                           paint: AnyPaint.auto(values[5]!),
                           strokeStyle: values.count == 6 ? nil : StrokeWrapper(strokeWidth: values[6] as? Float ?? 5, strokeType: values[safe: 7] as? Stroke ?? .elongated, strokeDashArray: values[safe: 8] as? GRPHArray ?? GRPHArray([], of: SimpleType.float)))
        }
        reg.implement(constructor: SimpleType.Line.constructor!) { type, context, values in
            return GLine(givenName: values[0] as? String,
                         start: values[1] as! Pos,
                         end: values[2] as! Pos,
                         positionZ: values[3] as? Int ?? 0,
                         paint: AnyPaint.auto(values[4]!),
                         strokeStyle: StrokeWrapper(strokeWidth: values[safe: 5] as? Float ?? 5, strokeType: values[safe: 6] as? Stroke ?? .elongated, strokeDashArray: values[safe: 7] as? GRPHArray ?? GRPHArray([], of: SimpleType.float)))
        }
        reg.implement(constructor: SimpleType.Polygon.constructor!) { type, context, values in
            return GPolygon(givenName: values[0] as? String,
                            points: values.count > 6 ? values[6...].map { $0 as! Pos } : [],
                            positionZ: values[1] as? Int ?? 0,
                            paint: AnyPaint.auto(values[2]!),
                            strokeStyle: (values[safe: 3] == nil && values[safe: 4] == nil && values[safe: 5] == nil) ? nil : StrokeWrapper(strokeWidth: values[safe: 3] as? Float ?? 5, strokeType: values[safe: 4] as? Stroke ?? .elongated, strokeDashArray: values[safe: 5] as? GRPHArray ?? GRPHArray([], of: SimpleType.float)))
        }
        reg.implement(constructor: SimpleType.Text.constructor!) { type, context, values in
            return GText(givenName: (values[0] as! String),
                         position: values[1] as! Pos,
                         positionZ: values[2] as? Int ?? 0,
                         font: values[3] as? JFont ?? JFont(size: values[3] as! Int),
                         rotation: values[4] as? Rotation ?? 0,
                         paint: AnyPaint.auto(values[5]!))
        }
        reg.implement(constructor: SimpleType.Path.constructor!) { type, context, values in
            return GPath(givenName: values[0] as? String,
                         positionZ: values[1] as? Int ?? 0,
                         rotation: values[2] as? Rotation ?? 0,
                         paint: AnyPaint.auto(values[3]!),
                         strokeStyle: values.count == 4 ? nil : StrokeWrapper(strokeWidth: values[4] as? Float ?? 5, strokeType: values[safe: 5] as? Stroke ?? .elongated, strokeDashArray: values[safe: 6] as? GRPHArray ?? GRPHArray([], of: SimpleType.float)))
        }
        reg.implement(constructor: SimpleType.Group.constructor!) { type, context, values in
            return GGroup(givenName: values[0] as? String,
                          positionZ: values[1] as? Int ?? 0,
                          rotation: values[2] as? Rotation ?? 0,
                          shapes: values.count > 3 ? values[3...].map { $0 as! GShape } : [])
        }
        reg.implement(constructor: SimpleType.Background.constructor!) { type, context, values in
            // if affected to `back`, its content will be copied to the original. this instance will never be used.
            return GImage(size: values[0] as! Pos, background: AnyPaint.auto(values[1]!), delegate: {})
        }
        
        // Generic Types
        
        reg.implement(constructorWithSignature: "T?(T wrapped?)") { type, ctx, values in
            if values.count == 1 {
                return GRPHOptional.some(values[0]!)
            } else {
                return GRPHOptional.null
            }
        }
        reg.implement(constructorWithSignature: "{T}(T wrapped...)") { type, ctx, values in
            GRPHArray(values.compactMap { $0 }, of: (type as! ArrayType).content)
        }
        reg.implement(constructorWithSignature: "{T}(T wrapped...)") { type, ctx, values in
            GRPHArray(values.compactMap { $0 }, of: (type as! ArrayType).content)
        }
        reg.implement(constructorWithSignature: "funcref<T><>(T wrapped)") { type, ctx, values in
            FuncRef(currentType: type as! FuncRefType, storage: .constant(values[safe: 0] ?? GRPHVoid.void))
        }
    }
}
