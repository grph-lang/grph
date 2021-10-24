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

public struct TupleType: GRPHType {
    public let content: [GRPHType]
    
    public var string: String {
        "tuple<\(content.map(\.string).joined(separator: "+"))>"
    }
    
    public func isInstance(of other: GRPHType) -> Bool {
        if let option = other as? OptionalType {
            return isInstance(of: option.wrapped)
        }
        if let tuple = other as? TupleType,
           tuple.content.count == content.count {
            return zip(content, tuple.content).allSatisfy({ $0.isInstance(of: $1) })
        }
        return other.isTheMixed
    }
    
    public var fields: [Field] {
        return content.enumerated().map { i, t in
            VirtualField<GRPHTuple>(name: "$\(i)", type: t, getter: { $0.wrapped[i] }, setter: { tuple, newValue in
                tuple.wrapped[i] = newValue
            })
        }
    }
    
    public var constructor: Constructor? {
        Constructor(parameters: content.enumerated().map { i, t in
            Parameter(name: "$\(i)", type: t)
        }, type: self, storage: .generic(signature: "tuple(T wrapped...)"))
    }
}
