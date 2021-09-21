//
//  FuncRef.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 25/08/2021.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct FuncRef: GRPHValue {
    public var currentType: FuncRefType
    public var storage: Storage
    
    public init(currentType: FuncRefType, storage: FuncRef.Storage) {
        self.currentType = currentType
        self.storage = storage
    }
    
    public var funcName: String {
        switch storage {
        case .function(let function, _):
            return "function \(function.fullyQualifiedName)"
        case .lambda(let lambda, _):
            return "lambda at line \(lambda.line)"
        case .constant(_):
            return "constant expression"
        }
    }
    
    public var type: GRPHType { currentType }
    
    public func isEqual(to other: GRPHValue) -> Bool {
        false // not even equal to itself, it makes no sense to compare function references
    }
}

public extension FuncRef {
    enum Storage {
        case function(Function, argumentGrid: [Bool])
        case lambda(Lambda, capture: [Variable])
        case constant(GRPHValue)
    }
}
