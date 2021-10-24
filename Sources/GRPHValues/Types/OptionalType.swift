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

public struct OptionalType: GRPHType {
    public let wrapped: GRPHType
    
    public var string: String {
        if wrapped is MultiOrType {
            return "<\(wrapped.string)>?"
        }
        return "\(wrapped.string)?"
    }
    
    public func isInstance(of other: GRPHType) -> Bool {
        return other is OptionalType && wrapped.isInstance(of: (other as! OptionalType).wrapped)
    }
    
    public var constructor: Constructor? {
        Constructor(parameters: [Parameter(name: "wrapped", type: wrapped, optional: true)], type: self, storage: .generic(signature: "T?(T wrapped?)"))
    }
}
