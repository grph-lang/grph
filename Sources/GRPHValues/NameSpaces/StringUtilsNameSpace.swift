//
//  StringUtilsNameSpace.swift
//  Graphism
//
//  Created by Emil Pedersen on 12/07/2020.
//

import Foundation

struct StringUtilsNameSpace: NameSpace {
    var name: String { "strutils" }
    
    var exportedFunctions: [Function] {
        [
            Function(ns: self, name: "getStringLength", parameters: [Parameter(name: "string", type: SimpleType.string)], returnType: SimpleType.integer),
            Function(ns: self, name: "substring", parameters: [Parameter(name: "string", type: SimpleType.string), Parameter(name: "start", type: SimpleType.integer), Parameter(name: "end", type: SimpleType.integer, optional: true)], returnType: SimpleType.string),
            Function(ns: self, name: "indexInString", parameters: [Parameter(name: "string", type: SimpleType.string), Parameter(name: "substring", type: SimpleType.string)], returnType: SimpleType.integer),
            Function(ns: self, name: "lastIndexInString", parameters: [Parameter(name: "string", type: SimpleType.string), Parameter(name: "substring", type: SimpleType.string)], returnType: SimpleType.integer),
            Function(ns: self, name: "stringContains", parameters: [Parameter(name: "string", type: SimpleType.string), Parameter(name: "substring", type: SimpleType.string)], returnType: SimpleType.boolean),
            Function(ns: self, name: "charToInteger", parameters: [Parameter(name: "char", type: SimpleType.string)], returnType: SimpleType.integer),
            Function(ns: self, name: "integerToChar", parameters: [Parameter(name: "codePoint", type: SimpleType.integer)], returnType: SimpleType.string),
            Function(ns: self, name: "split", parameters: [Parameter(name: "string", type: SimpleType.string), Parameter(name: "substring", type: SimpleType.string)], returnType: SimpleType.string.inArray),
            Function(ns: self, name: "joinStrings", parameters: [Parameter(name: "strings", type: SimpleType.string.inArray), Parameter(name: "delimiter", type: SimpleType.string, optional: true)], returnType: SimpleType.string),
            Function(ns: self, name: "setStringLength", parameters: [Parameter(name: "string", type: SimpleType.string), Parameter(name: "length", type: SimpleType.integer), Parameter(name: "fill", type: SimpleType.string, optional: true)], returnType: SimpleType.string),
        ]
    }
}
