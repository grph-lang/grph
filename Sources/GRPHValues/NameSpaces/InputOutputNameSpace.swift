//
//  InputOutputNameSpace.swift
//  Graphism
//
//  Created by Emil Pedersen on 12/07/2020.
//

import Foundation

struct InputOutputNameSpace: NameSpace {
    var name: String { "stdio" }
    
    var exportedFunctions: [Function] {
        [
            Function(ns: self, name: "getLineInString", parameters: [Parameter(name: "string", type: SimpleType.string), Parameter(name: "line", type: SimpleType.integer)], returnType: SimpleType.string),
            Function(ns: self, name: "getLinesInString", parameters: [Parameter(name: "string", type: SimpleType.string)], returnType: SimpleType.string.inArray),
            Function(ns: self, name: "getMousePos", parameters: [], returnType: SimpleType.pos.optional),
            Function(ns: self, name: "getTimeInMillisSinceLoad", parameters: [], returnType: SimpleType.integer),
            Function(ns: self, name: "getSVGFromCurrentImage", parameters: [], returnType: SimpleType.string),
        ]
    }
}
