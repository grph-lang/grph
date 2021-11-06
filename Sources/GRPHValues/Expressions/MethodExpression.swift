//
//  MethodExpression.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 13/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct MethodExpression: Expression {
    public let method: Method
    public let on: Expression
    public let values: [Expression?]
    
    public init(ctx: CompilingContext, method: Method, on: Expression, values: [Expression], asInstruction: Bool = false) throws {
        self.method = method
        self.on = on
        guard asInstruction || !method.returnType.isTheVoid else {
            throw GRPHCompileError(type: .typeMismatch, message: "Void function can't be used as an expression")
        }
        self.values = try method.populateArgumentList(ctx: ctx, values: values, nameForErrors: "method '\(method.inType)>\(method.name)'")
    }
    
    public func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        return method.returnType
    }
    
    public var fullyQualified: String {
        method.fullyQualifiedName
    }
    
    public var string: String {
        "\(on.bracketized).\(fullyQualified)[\(method.formattedParameterList(values: values.compactMap {$0}))]"
    }
    
    public var needsBrackets: Bool { false }
}
