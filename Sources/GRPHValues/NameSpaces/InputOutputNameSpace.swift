//
//  InputOutputNameSpace.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 12/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct InputOutputNameSpace: NameSpace {
    public var name: String { "stdio" }
    
    public var exportedFunctions: [Function] {
        [
            Function(ns: self, name: "getLineInString", parameters: [Parameter(name: "string", type: SimpleType.string), Parameter(name: "line", type: SimpleType.integer)], returnType: SimpleType.string),
            Function(ns: self, name: "getLinesInString", parameters: [Parameter(name: "string", type: SimpleType.string)], returnType: SimpleType.string.inArray),
            Function(ns: self, name: "getMousePos", parameters: [], returnType: SimpleType.pos.optional),
            Function(ns: self, name: "getTimeInMillisSinceLoad", parameters: [], returnType: SimpleType.integer),
            Function(ns: self, name: "getSVGFromCurrentImage", parameters: [], returnType: SimpleType.string),
            Function(ns: self, name: "printOut", parameters: [Parameter(name: "message", type: SimpleType.string)], returnType: SimpleType.void),
            Function(ns: self, name: "printError", parameters: [Parameter(name: "message", type: SimpleType.string)], returnType: SimpleType.void),
        ]
    }
}
