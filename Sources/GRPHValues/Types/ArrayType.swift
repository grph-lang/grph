//
//  GRPHType.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 30/06/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct ArrayType: GRPHType {
    public let content: GRPHType
    
    public var string: String {
        "{\(content.string)}"
    }
    
    public var supertype: GRPHType {
        if content.isTheMixed {
            return SimpleType.mixed
        }
        return ArrayType(content: content.supertype)
    }
    
    public func isInstance(of other: GRPHType) -> Bool {
        if let option = other as? OptionalType {
            return isInstance(of: option.wrapped)
        }
        if let array = other as? ArrayType {
            return content.isInstance(of: array.content)
        }
        return other.isTheMixed
    }
    
    public var fields: [Field] {
        return [VirtualField<GRPHArray>(name: "length", type: SimpleType.integer, getter: { $0.count })]
    }
    
    public var constructor: Constructor? {
        Constructor(parameters: [Parameter(name: "element", type: content, optional: true)], type: self, varargs: true, storage: .generic(signature: "{T}(T wrapped...)"))
    }
    
    public var includedMethods: [Method] {
        [
            Method(ns: RandomNameSpace(), name: "shuffled", inType: self, parameters: [], returnType: self, storage: .generic(signature: "{T} {T}.random>shuffled[]")),
            Method(ns: StandardNameSpace(), name: "copy", inType: self, parameters: [], returnType: self, storage: .generic(signature: "{T} {T}.copy[]"))
        ]
    }
}
