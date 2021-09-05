//
//  FieldExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
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
