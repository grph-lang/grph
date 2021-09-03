//
//  StandardNameSpace.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation

struct StandardNameSpace: NameSpace {
    var name: String { "standard" }
    
    var exportedTypes: [GRPHType] {
        SimpleType.allCases
    }
    
    var exportedTypeAliases: [TypeAlias] {
        [
            TypeAlias(name: "farray", type: SimpleType.float.inArray),
            TypeAlias(name: "array", type: SimpleType.mixed.inArray),
            TypeAlias(name: "int", type: SimpleType.integer),
            TypeAlias(name: "Square", type: SimpleType.Rectangle),
            TypeAlias(name: "Rect", type: SimpleType.Rectangle),
            TypeAlias(name: "R", type: SimpleType.Rectangle),
            TypeAlias(name: "Ellipse", type: SimpleType.Circle),
            TypeAlias(name: "E", type: SimpleType.Circle),
            TypeAlias(name: "C", type: SimpleType.Circle),
            TypeAlias(name: "L", type: SimpleType.Line),
            TypeAlias(name: "Poly", type: SimpleType.Polygon),
            TypeAlias(name: "P", type: SimpleType.Polygon),
            TypeAlias(name: "T", type: SimpleType.Text),
            TypeAlias(name: "G", type: SimpleType.Group),
            TypeAlias(name: "Back", type: SimpleType.Background)
        ]
    }
    
    var exportedFunctions: [Function] {
        return [
            constructorLegacyFunction(type: SimpleType.color),
            constructorLegacyFunction(type: SimpleType.linear),
            constructorLegacyFunction(type: SimpleType.radial),
            constructorLegacyFunction(type: SimpleType.font),
            Function(ns: self, name: "colorFromInt", parameters: [Parameter(name: "value", type: SimpleType.integer)], returnType: SimpleType.color),
            // file manipulation functions removed
            Function(ns: self, name: "stringToInteger", parameters: [Parameter(name: "string", type: SimpleType.string)], returnType: SimpleType.integer.optional),
            Function(ns: self, name: "stringToFloat", parameters: [Parameter(name: "string", type: SimpleType.string)], returnType: SimpleType.float.optional),
            Function(ns: self, name: "toString", parameters: [Parameter(name: "text...", type: SimpleType.mixed)], returnType: SimpleType.string, varargs: true),
            Function(ns: self, name: "concat", parameters: [Parameter(name: "text...", type: SimpleType.mixed)], returnType: SimpleType.string, varargs: true),
            Function(ns: self, name: "log", parameters: [Parameter(name: "text...", type: SimpleType.mixed)], returnType: SimpleType.string, varargs: true),
            // getters for fields removed
            Function(ns: self, name: "getRotation", parameters: [Parameter(name: "shape", type: SimpleType.shape)], returnType: SimpleType.rotation),
            Function(ns: self, name: "getPosition", parameters: [Parameter(name: "shape", type: SimpleType.shape)], returnType: SimpleType.pos),
            Function(ns: self, name: "getSize", parameters: [Parameter(name: "shape", type: SimpleType.shape)], returnType: SimpleType.pos),
            Function(ns: self, name: "getCenterPoint", parameters: [Parameter(name: "shape", type: SimpleType.shape)], returnType: SimpleType.pos),
            Function(ns: self, name: "getName", parameters: [Parameter(name: "shape", type: SimpleType.shape)], returnType: SimpleType.string),
            Function(ns: self, name: "getPaint", parameters: [Parameter(name: "shape", type: SimpleType.shape)], returnType: SimpleType.paint),
            Function(ns: self, name: "getStrokeWidth", parameters: [Parameter(name: "shape", type: SimpleType.shape)], returnType: SimpleType.float),
            Function(ns: self, name: "getStrokeType", parameters: [Parameter(name: "shape", type: SimpleType.shape)], returnType: SimpleType.stroke),
            Function(ns: self, name: "getStrokeDashArray", parameters: [Parameter(name: "shape", type: SimpleType.shape)], returnType: SimpleType.float.inArray),
            Function(ns: self, name: "isFilled", parameters: [Parameter(name: "shape", type: SimpleType.shape)], returnType: SimpleType.boolean),
            Function(ns: self, name: "getZPos", parameters: [Parameter(name: "shape", type: SimpleType.shape)], returnType: SimpleType.integer),
            Function(ns: self, name: "getFont", parameters: [Parameter(name: "shape", type: SimpleType.Text)], returnType: SimpleType.font),
            Function(ns: self, name: "getPoint", parameters: [Parameter(name: "shape", type: SimpleType.Polygon), Parameter(name: "index", type: SimpleType.integer)], returnType: SimpleType.pos),
            Function(ns: self, name: "getXForPos", parameters: [Parameter(name: "pos", type: SimpleType.pos)], returnType: SimpleType.float),
            Function(ns: self, name: "getYForPos", parameters: [Parameter(name: "pos", type: SimpleType.pos)], returnType: SimpleType.float),
            Function(ns: self, name: "integerToRotation", parameters: [Parameter(name: "integer", type: SimpleType.integer)], returnType: SimpleType.rotation),
            Function(ns: self, name: "rotationToInteger", parameters: [Parameter(name: "rotation", type: SimpleType.rotation)], returnType: SimpleType.integer),
            Function(ns: self, name: "getValueInArray", parameters: [Parameter(name: "farray", type: SimpleType.float.inArray), Parameter(name: "index", type: SimpleType.integer)], returnType: SimpleType.float),
            Function(ns: self, name: "getArrayLength", parameters: [Parameter(name: "farray", type: SimpleType.mixed.inArray)], returnType: SimpleType.integer),
            Function(ns: self, name: "getShape", parameters: [Parameter(name: "index", type: SimpleType.integer)], returnType: SimpleType.shape),
            // getShapeAt, intersects posAround, cloneShape etc missing TODO
            Function(ns: self, name: "getShapeNamed", parameters: [Parameter(name: "name", type: SimpleType.string)], returnType: SimpleType.shape.optional),
            Function(ns: self, name: "getNumberOfShapes", parameters: [], returnType: SimpleType.integer),
            Function(ns: self, name: "createPos", parameters: [Parameter(name: "x", type: SimpleType.num), Parameter(name: "y", type: SimpleType.num)], returnType: SimpleType.pos),
            Function(ns: self, name: "clippedShape", parameters: [Parameter(name: "shape", type: SimpleType.shape), Parameter(name: "clip", type: SimpleType.shape)], returnType: SimpleType.shape),
            Function(ns: self, name: "isInGroup", parameters: [Parameter(name: "group", type: SimpleType.shape), Parameter(name: "shape", type: SimpleType.shape)], returnType: SimpleType.boolean),
            Function(ns: self, name: "range", parameters: [Parameter(name: "first", type: SimpleType.integer), Parameter(name: "last", type: SimpleType.integer), Parameter(name: "step", type: SimpleType.integer, optional: true)], returnType: SimpleType.integer.inArray),
            // == Migrated methods ==
            Function(ns: self, name: "validate", parameters: [Parameter(name: "shape", type: SimpleType.shape)]),
            Function(ns: self, name: "validateAll", parameters: []),
            Function(ns: self, name: "unvalidate", parameters: [Parameter(name: "shape", type: SimpleType.shape)]),
            Function(ns: self, name: "update", parameters: []),
            Function(ns: self, name: "wait", parameters: [Parameter(name: "time", type: SimpleType.integer)]),
            Function(ns: self, name: "end", parameters: []),
            // LEGACY
            Function(ns: self, name: "setHCentered", parameters: [Parameter(name: "shape", type: SimpleType.shape)]),
            Function(ns: self, name: "setLeftAligned", parameters: [Parameter(name: "shape", type: SimpleType.shape)]),
            Function(ns: self, name: "setRightAligned", parameters: [Parameter(name: "shape", type: SimpleType.shape)]),
            Function(ns: self, name: "setVCentered", parameters: [Parameter(name: "shape", type: SimpleType.shape)]),
            Function(ns: self, name: "setTopAligned", parameters: [Parameter(name: "shape", type: SimpleType.shape)]),
            Function(ns: self, name: "setBottomAligned", parameters: [Parameter(name: "shape", type: SimpleType.shape)]),
        ]
    }
    
    var exportedMethods: [Method] {
        [
            Method(ns: self, name: "rotate", inType: SimpleType.shape, parameters: [Parameter(name: "addRotation", type: SimpleType.rotation)]),
            Method(ns: self, name: "setRotation", inType: SimpleType.shape, parameters: [Parameter(name: "newRotation", type: SimpleType.rotation)]),
            Method(ns: self, name: "setRotationCenter", inType: SimpleType.shape, parameters: [Parameter(name: "rotationCenter", type: SimpleType.pos.optional)]),
            Method(ns: self, name: "translate", inType: SimpleType.shape, parameters: [Parameter(name: "translation", type: SimpleType.pos)]),
            Method(ns: self, name: "setPosition", inType: SimpleType.shape, parameters: [Parameter(name: "newPosition", type: SimpleType.pos)]),
            // ON SHAPES
            Method(ns: self, name: "setHCentered", inType: SimpleType.shape, parameters: []),
            Method(ns: self, name: "setLeftAligned", inType: SimpleType.shape, parameters: []),
            Method(ns: self, name: "setRightAligned", inType: SimpleType.shape, parameters: []),
            Method(ns: self, name: "setVCentered", inType: SimpleType.shape, parameters: []),
            Method(ns: self, name: "setTopAligned", inType: SimpleType.shape, parameters: []),
            Method(ns: self, name: "setBottomAligned", inType: SimpleType.shape, parameters: []),
            // TODO mirror
            Method(ns: self, name: "grow", inType: SimpleType.shape, parameters: [Parameter(name: "extension", type: SimpleType.pos)]),
            Method(ns: self, name: "setSize", inType: SimpleType.shape, parameters: [Parameter(name: "newSize", type: SimpleType.pos)]),
            Method(ns: self, name: "setName", inType: SimpleType.shape, parameters: [Parameter(name: "newName", type: SimpleType.string)]),
            Method(ns: self, name: "setPaint", inType: SimpleType.shape, parameters: [Parameter(name: "newPaint", type: SimpleType.paint)]),
            Method(ns: self, name: "setStroke", inType: SimpleType.shape, parameters: [.strokeWidth, .strokeType, .strokeDashArray]),
            Method(ns: self, name: "filling", inType: SimpleType.shape, parameters: [Parameter(name: "fill", type: SimpleType.boolean)]),
            Method(ns: self, name: "setZPos", inType: SimpleType.shape, parameters: [Parameter(name: "zpos", type: SimpleType.integer)]),
            // Polygons
            Method(ns: self, name: "addPoint", inType: SimpleType.Polygon, parameters: [Parameter(name: "point", type: SimpleType.pos)]),
            Method(ns: self, name: "setPoint", inType: SimpleType.Polygon, parameters: [Parameter(name: "index", type: SimpleType.integer), Parameter(name: "point", type: SimpleType.pos)]),
            Method(ns: self, name: "setPoints", inType: SimpleType.Polygon, parameters: [Parameter(name: "points...", type: SimpleType.pos)], varargs: true),
            // Paths
            Method(ns: self, name: "moveTo", inType: SimpleType.Path, parameters: [Parameter(name: "point", type: SimpleType.pos)]),
            Method(ns: self, name: "lineTo", inType: SimpleType.Path, parameters: [Parameter(name: "point", type: SimpleType.pos)]),
            Method(ns: self, name: "quadTo", inType: SimpleType.Path, parameters: [Parameter(name: "ctrl", type: SimpleType.pos), Parameter(name: "point", type: SimpleType.pos)]),
            Method(ns: self, name: "cubicTo", inType: SimpleType.Path, parameters: [Parameter(name: "ctrl1", type: SimpleType.pos), Parameter(name: "ctrl2", type: SimpleType.pos), Parameter(name: "point", type: SimpleType.pos)]),
            Method(ns: self, name: "closePath", inType: SimpleType.Path, parameters: []),
            Method(ns: self, name: "addToGroup", inType: SimpleType.Group, parameters: [Parameter(name: "shape", type: SimpleType.shape)]),
            Method(ns: self, name: "removeFromGroup", inType: SimpleType.Group, parameters: [Parameter(name: "shape", type: SimpleType.shape)]),
            // TODO selection
        ]
    }
    
    func constructorLegacyFunction(type: GRPHType) -> Function {
        let base = type.constructor!
        return Function(ns: self, name: type.string, parameters: base.parameters, returnType: type, varargs: base.varargs)
    }
}
