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

public struct FuncRefType: GRPHType {
    public let returnType: GRPHType
    public let parameterTypes: [GRPHType]
    
    public var string: String {
        "funcref<\(returnType.string)><\(parameterTypes.map{ $0.string }.joined(separator: "+"))>"
    }
    
    public var supertype: GRPHType {
        if returnType.isTheMixed {
            return SimpleType.funcref
        }
        return FuncRefType(returnType: returnType.supertype, parameterTypes: parameterTypes)
    }
    
    public func isInstance(of other: GRPHType) -> Bool {
        if let option = other as? OptionalType {
            return isInstance(of: option.wrapped)
        }
        if let other = other as? FuncRefType,
           self.parameterTypes.count == other.parameterTypes.count {
            // (funcref<num><integer+num>(5) is funcref<mixed><integer+integer>) == true
            return self.returnType.isInstance(of: other.returnType)
        }
        if let simple = other as? SimpleType {
            if simple == .funcref || simple == .mixed {
                return true
            }
        }
        return false
    }
    
    public var constructor: Constructor? {
        Constructor(parameters: [Parameter(name: "constant", type: returnType, optional: returnType.isTheVoid)], type: self, storage: .generic(signature: "funcref<T><>(T wrapped)"))
    }
}

extension FuncRefType: Parametrable {
    public var parameters: [Parameter] {
        parameterTypes.enumerated().map { index, type in
            Parameter(name: "$\(index)", type: type)
        }
    }
    
    public var varargs: Bool { false }
}
