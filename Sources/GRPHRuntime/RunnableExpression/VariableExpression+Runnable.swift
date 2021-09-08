//
//  VariableExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation
import GRPHValues

extension VariableExpression: RunnableExpression {
    func eval(context: RuntimeContext) throws -> GRPHValue {
        if let v = context.findVariable(named: name) {
            return v.content!
        }
        throw GRPHRuntimeError(type: .invalidArgument, message: "Undeclared variable '\(name)'")
    }
}

extension VariableExpression: RunnableAssignableExpression {
    func eval(context: RuntimeContext, cache: inout [GRPHValue]) throws -> GRPHValue {
        try eval(context: context)
    }
    
    func assign(context: RuntimeContext, value: GRPHValue, cache: inout [GRPHValue]) throws {
        if let v = context.findVariable(named: name) {
            if v.name == "back" {
                let new = value as! GImage
                let old = context.runtime.image
                old.paint = new.paint
                old.size = new.size
                old.shapes = new.shapes
            } else {
                try v.setContent(value)
            }
            if v.type.isInstance(of: SimpleType.shape) {
                context.runtime.triggerAutorepaint()
            }
            if context.runtime.debugging {
                printout("[DEBUG VAR \(v.name)=\(v.content!)]")
            }
        }
    }
}
