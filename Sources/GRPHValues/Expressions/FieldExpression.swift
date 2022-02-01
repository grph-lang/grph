//
//  FieldExpression.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 03/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct FieldExpression: Expression {
    public let on: Expression
    public let field: Field
    
    public init(on: Expression, field: Field) {
        self.on = on
        self.field = field
    }
    
    public func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        field.type
    }
    
    public var string: String {
        "\(on.bracketized).\(field.name)"
    }
    
    public var needsBrackets: Bool { false }
}

extension FieldExpression: AssignableExpression {
    public func checkCanAssign(context: CompilingContext) throws {
        guard field.writeable else {
            throw GRPHCompileError(type: .typeMismatch, message: "Cannot assign to final field '\(field.type).\(field.name)'")
        }
    }
}

public extension FieldExpression {
    var astNodeData: String {
        "retrieve field \(field.name) of type \(field.type)"
    }
    
    var astChildren: [ASTElement] {
        [
            ASTElement(name: "value", value: [on])
        ]
    }
}

public struct ConstantPropertyExpression: Expression {
    public let property: TypeConstant
    public let inType: GRPHType
    
    public init(property: TypeConstant, inType: GRPHType) {
        self.property = property
        self.inType = inType
    }
    
    public func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        property.type
    }
    
    public var string: String {
        "\(inType.string).\(property.name)"
    }
    
    public var needsBrackets: Bool { false }
}

public extension ConstantPropertyExpression {
    var astNodeData: String {
        "retrieve static property \(property.name) in type \(inType)"
    }
    
    var astChildren: [ASTElement] { [] }
}

// These could return types directly in a future version

public struct ValueTypeExpression: Expression {
    public let on: Expression
    
    public init(on: Expression) {
        self.on = on
    }
    
    public func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        SimpleType.string
    }
    
    public var string: String {
        "\(on.bracketized).type"
    }
    
    public var needsBrackets: Bool { false }
}

public extension ValueTypeExpression {
    var astNodeData: String {
        "retrieve string describing the type of the given value"
    }
    
    var astChildren: [ASTElement] {
        [ASTElement(name: "value", value: [on])]
    }
}

public struct TypeValueExpression: Expression {
    public let type: GRPHType
    
    public init(type: GRPHType) {
        self.type = type
    }
    
    public func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        SimpleType.string
    }
    
    public var string: String {
        "[\(type.string)].TYPE"
    }
    
    public var needsBrackets: Bool { false }
}

public extension TypeValueExpression {
    var astNodeData: String {
        "retrieve type \(type) as string"
    }
    
    var astChildren: [ASTElement] { [] }
}
