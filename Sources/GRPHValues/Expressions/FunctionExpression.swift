//
//  FunctionExpression.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 06/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct FunctionExpression: Expression {
    public let function: Function
    public let values: [Expression?]
    
    public init(ctx: CompilingContext, function: Function, values: [Expression], asInstruction: Bool = false) throws {
        self.function = function
        guard asInstruction || !function.returnType.isTheVoid else {
            throw GRPHCompileError(type: .typeMismatch, message: "Void function can't be used as an expression")
        }
        self.values = try function.populateArgumentList(ctx: ctx, values: values, nameForErrors: "function '\(function.name)'")
    }
    
    public func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        return function.returnType
    }
    
    public var string: String {
        "\(function.fullyQualifiedName)[\(function.formattedParameterList(values: values.compactMap {$0}))]"
    }
    
    public var needsBrackets: Bool { false }
}
