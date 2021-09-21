//
//  ReflectNameSpace.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 18/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct ReflectNameSpace: NameSpace {
    public var name: String { "reflect" }
    
    public var exportedFunctions: [Function] {
        [
            Function(ns: self, name: "callFunction", parameters: [Parameter(name: "funcName", type: SimpleType.string), Parameter(name: "namespace", type: SimpleType.string, optional: true), Parameter(name: "params...", type: SimpleType.mixed)], returnType: SimpleType.mixed, varargs: true),
            Function(ns: self, name: "callFunctionAsync", parameters: [Parameter(name: "funcName", type: MultiOrType(type1: SimpleType.string, type2: SimpleType.funcref)), Parameter(name: "params...", type: SimpleType.mixed)], returnType: SimpleType.void, varargs: true),
            Function(ns: self, name: "callFuncref", parameters: [Parameter(name: "function", type: SimpleType.funcref), Parameter(name: "params...", type: SimpleType.mixed)], returnType: SimpleType.mixed, varargs: true),
            Function(ns: self, name: "callMethod", parameters: [Parameter(name: "methodName", type: SimpleType.string), Parameter(name: "namespace", type: SimpleType.string), Parameter(name: "on", type: SimpleType.mixed), Parameter(name: "params...", type: SimpleType.mixed)], returnType: SimpleType.mixed, varargs: true),
            Function(ns: self, name: "callConstructor", parameters: [Parameter(name: "type", type: SimpleType.string), Parameter(name: "params...", type: SimpleType.mixed)], returnType: SimpleType.mixed, varargs: true),
            Function(ns: self, name: "castTo", parameters: [Parameter(name: "type", type: SimpleType.string), Parameter(name: "param", type: SimpleType.mixed)], returnType: SimpleType.mixed),
            Function(ns: self, name: "getVersion", parameters: [Parameter(name: "of", type: SimpleType.string, optional: true)], returnType: SimpleType.string),
            Function(ns: self, name: "hasVersion", parameters: [Parameter(name: "of", type: SimpleType.string), Parameter(name: "min", type: SimpleType.string, optional: true)], returnType: SimpleType.boolean),
            Function(ns: self, name: "getType", parameters: [Parameter(name: "of", type: SimpleType.mixed)], returnType: SimpleType.string),
            Function(ns: self, name: "getDeclaredType", parameters: [Parameter(name: "var", type: SimpleType.string)], returnType: SimpleType.string),
            Function(ns: self, name: "getVarValue", parameters: [Parameter(name: "var", type: SimpleType.string)], returnType: SimpleType.mixed),
            Function(ns: self, name: "isVarFinal", parameters: [Parameter(name: "var", type: SimpleType.string)], returnType: SimpleType.boolean),
            Function(ns: self, name: "isVarDeclared", parameters: [Parameter(name: "var", type: SimpleType.string)], returnType: SimpleType.boolean),
            Function(ns: self, name: "declareVar", parameters: [
                Parameter(name: "name", type: SimpleType.string),
                Parameter(name: "global", type: SimpleType.boolean, optional: true),
                Parameter(name: "type", type: SimpleType.string),
                Parameter(name: "value", type: SimpleType.mixed),
            ]),
            Function(ns: self, name: "setVarValue", parameters: [
                Parameter(name: "name", type: SimpleType.string),
                Parameter(name: "value", type: SimpleType.mixed),
            ]),
            Function(ns: self, name: "getLambdaCaptureList", parameters: [
                Parameter(name: "lambda", type: SimpleType.funcref)
            ], returnType: SimpleType.string.inArray),
            Function(ns: self, name: "getLambdaCapturedVar", parameters: [
                Parameter(name: "lambda", type: SimpleType.funcref),
                Parameter(name: "name", type: SimpleType.string),
                Parameter(name: "replaceContentWith", type: SimpleType.mixed, optional: true),
            ], returnType: SimpleType.mixed),
        ]
    }
}
