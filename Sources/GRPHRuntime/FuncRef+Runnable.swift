//
//  FuncRef.swift
//  FuncRef
//
//  Created by Emil Pedersen on 25/08/2021.
//

import Foundation
import GRPHValues

extension FuncRef {
    func execute(context: RuntimeContext, params: [GRPHValue?]) throws -> GRPHValue {
        switch storage {
        case .function(let function, let argumentGrid):
            var i = 0
            let parmap: [GRPHValue?] = argumentGrid.map {
                if $0 {
                    defer {
                        i += 1
                    }
                    return params[i]
                } else {
                    return nil
                }
            }
            return try function.execute(context: context, arguments: parmap)
        case .lambda(let lambda, let capture):
            return try lambda.execute(context: context, params: params, capture: capture)
        case .constant(let const):
            return const
        }
    }
}
