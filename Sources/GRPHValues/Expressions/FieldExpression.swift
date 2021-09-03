//
//  FieldExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation

struct FieldExpression: Expression {
    let on: Expression
    let field: Field
    
    func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        field.type
    }
    
    var string: String {
        "\(on.bracketized).\(field.name)"
    }
    
    var needsBrackets: Bool { false }
}

extension FieldExpression: AssignableExpression {
    func checkCanAssign(context: CompilingContext) throws {
        guard field.writeable else {
            throw GRPHCompileError(type: .typeMismatch, message: "Cannot assign to final field '\(field.type).\(field.name)'")
        }
    }
}

struct ConstantPropertyExpression: Expression {
    let property: TypeConstant
    let inType: GRPHType
    
    func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        property.type
    }
    
    var string: String {
        "\(inType.string).\(property.name)"
    }
    
    var needsBrackets: Bool { false }
}

// These could return types directly in a future version

struct ValueTypeExpression: Expression {
    let on: Expression
    
    func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        SimpleType.string
    }
    
    var string: String {
        "\(on.bracketized).type"
    }
    
    var needsBrackets: Bool { false }
}

struct TypeValueExpression: Expression {
    let type: GRPHType
    
    func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        SimpleType.string
    }
    
    var string: String {
        "[\(type.string)].TYPE"
    }
    
    var needsBrackets: Bool { false }
}
