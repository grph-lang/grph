//
//  ArrayValueExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

struct ArrayValueExpression: Expression {
    let varName: String
    let index: Expression?
    let removing: Bool
    
    internal init(context: CompilingContext, varName: String, index: Expression?, removing: Bool) throws {
        self.varName = varName
        self.index = index == nil ? nil : try GRPHTypes.autobox(context: context, expression: index!, expected: SimpleType.integer)
        self.removing = removing
    }
    
    func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        guard let v = context.findVariable(named: varName) else {
            throw GRPHCompileError(type: .undeclared, message: "Unknown variable '\(varName)'")
        }
        guard let type = GRPHTypes.autoboxed(type: v.type, expected: ArrayType(content: SimpleType.mixed)) as? ArrayType else {
            throw GRPHCompileError(type: .invalidArguments, message: "Array expression with non-array variable")
        }
        return type.content
    }
    
    var string: String { "\(varName){\(index?.string ?? "")\(removing ? "-" : "")}" }
    
    var needsBrackets: Bool { false }
}
