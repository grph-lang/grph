//
//  RandomNameSpace.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 12/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct RandomNameSpace: NameSpace {
    public var name: String { "random" }
    
    public var exportedFunctions: [Function] {
        [
            Function(ns: self, name: "randomInteger", parameters: [Parameter(name: "max", type: SimpleType.integer)], returnType: SimpleType.integer),
            Function(ns: self, name: "randomFloat", parameters: [], returnType: SimpleType.float),
            Function(ns: self, name: "randomString", parameters: [Parameter(name: "length", type: SimpleType.integer), Parameter(name: "characters", type: SimpleType.string, optional: true)], returnType: SimpleType.string),
            Function(ns: self, name: "randomBoolean", parameters: [], returnType: SimpleType.boolean),
            Function(ns: self, name: "shuffleString", parameters: [Parameter(name: "string", type: SimpleType.string)], returnType: SimpleType.string)
        ]
    }
    
    public var exportedMethods: [Method] {
        [
            Method(ns: self, name: "shuffled", inType: SimpleType.string, parameters: [], returnType: SimpleType.string),
            Method(ns: self, name: "shuffleArray", inType: SimpleType.mixed.inArray, parameters: [])
        ]
    }
}
