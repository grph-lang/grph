//
//  ConstructorExpression.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 05/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct ConstructorExpression: Expression {
    public let constructor: Constructor
    public let values: [Expression?]
    
    public init<T>(ctx: CompilingContext, type: GRPHType, values: [T], resolver: (T, GRPHType) throws -> Expression) throws {
        guard let constructor = type.constructor else {
            throw GRPHCompileError(type: .typeMismatch, message: "No constructor found in '\(type)'");
        }
        self.constructor = constructor
        // Java did kinda support multiple constructor but they didn't exist
        self.values = try constructor.populateArgumentList(ctx: ctx, values: values, resolver: resolver, nameForErrors: "constructor for '\(constructor.name)'")
    }
    
    public init(ctx: CompilingContext, boxing: Expression, infer: GRPHType) throws {
        self.constructor = try boxing.getType(context: ctx, infer: infer).optional.constructor!
        self.values = [boxing]
    }
    
    public func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        constructor.type
    }
    
    public var string: String {
        "\(constructor.type.string)(\(constructor.formattedParameterList(values: values.compactMap {$0})))"
    }
    
    public var needsBrackets: Bool { false }
}

public extension ConstructorExpression {
    var astNodeData: String {
        "invocation of \(constructor.signature)"
    }
    
    var astChildren: [ASTElement] {
        [
            ASTElement(name: "arguments", value: values.compactMap({ $0 }))
        ]
    }
}
