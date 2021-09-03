//
//  FuncRef.swift
//  FuncRef
//
//  Created by Emil Pedersen on 25/08/2021.
//

import Foundation

struct FuncRef: GRPHValue {
    
    var currentType: FuncRefType
    var storage: Storage
    
    var funcName: String {
        switch storage {
        case .function(let function, _):
            return "function \(function.fullyQualifiedName)"
        case .lambda(let lambda, _):
            return "lambda at line \(lambda.line)"
        case .constant(_):
            return "constant expression"
        }
    }
    
    var type: GRPHType { currentType }
    
    func isEqual(to other: GRPHValue) -> Bool {
        false // not even equal to itself, it makes no sense to compare function references
    }
}

extension FuncRef {
    enum Storage {
        case function(Function, argumentGrid: [Bool])
        case lambda(Lambda, capture: [Variable])
        case constant(GRPHValue)
    }
}
