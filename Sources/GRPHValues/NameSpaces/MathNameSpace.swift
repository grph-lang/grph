//
//  MathNameSpace.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 13/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct MathNameSpace: NameSpace {
    public var name: String { "math" }
    
    public var exportedFunctions: [Function] {
        [
            Function(ns: self, name: "sum", parameters: [Parameter(name: "numbers...", type: SimpleType.num)], returnType: SimpleType.float, varargs: true),
            Function(ns: self, name: "difference", parameters: [Parameter(name: "numbers...", type: SimpleType.num)], returnType: SimpleType.float, varargs: true),
            Function(ns: self, name: "multiply", parameters: [Parameter(name: "numbers...", type: SimpleType.num)], returnType: SimpleType.float, varargs: true),
            Function(ns: self, name: "divide", parameters: [Parameter(name: "numbers...", type: SimpleType.num)], returnType: SimpleType.float, varargs: true),
            Function(ns: self, name: "modulo", parameters: [Parameter(name: "numbers...", type: SimpleType.num)], returnType: SimpleType.float, varargs: true),
            Function(ns: self, name: "sqrt", parameters: [Parameter(name: "number", type: SimpleType.num)], returnType: SimpleType.float),
            Function(ns: self, name: "cbrt", parameters: [Parameter(name: "number", type: SimpleType.num)], returnType: SimpleType.float),
            Function(ns: self, name: "pow", parameters: [Parameter(name: "number", type: SimpleType.num), Parameter(name: "power", type: SimpleType.num)], returnType: SimpleType.float),
            Function(ns: self, name: "PI", parameters: [], returnType: SimpleType.float),
            Function(ns: self, name: "round", parameters: [Parameter(name: "number", type: SimpleType.num)], returnType: SimpleType.integer),
            Function(ns: self, name: "floor", parameters: [Parameter(name: "number", type: SimpleType.num)], returnType: SimpleType.integer),
            Function(ns: self, name: "ceil", parameters: [Parameter(name: "number", type: SimpleType.num)], returnType: SimpleType.integer), // asFloat is a cast, asChar is in strutils --> Removed
        ]
    }
}
