//
//  FieldExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation
import GRPHValues

extension FieldExpression: RunnableExpression {
    func eval(context: RuntimeContext) throws -> GRPHValue {
        field.getValue(on: try on.evalIfRunnable(context: context))
    }
}

extension FieldExpression: RunnableAssignableExpression {
    func eval(context: RuntimeContext, cache: inout [GRPHValue]) throws -> GRPHValue {
        if let on = on as? RunnableAssignableExpression {
            cache.append(try on.eval(context: context, cache: &cache))
        } else {
            cache.append(try on.evalIfRunnable(context: context))
        }
        return field.getValue(on: cache.last!)
    }
    
    func assign(context: RuntimeContext, value: GRPHValue, cache: inout [GRPHValue]) throws {
        var modified = cache.last!
        try field.setValue(on: &modified, value: value)
        // if 'modified' is a reference type, it is already updated
        if type(of: modified) is AnyClass {
            if modified is GShape {
                context.runtime.triggerAutorepaint()
            }
            return
        }
        cache.removeLast()
        if let on = on as? RunnableAssignableExpression {
            try on.assign(context: context, value: modified, cache: &cache)
        } else {
            throw GRPHRuntimeError(type: .unexpected, message: "Value type couldn't be modified back")
        }
    }
}

extension ConstantPropertyExpression: RunnableExpression {
    func eval(context: RuntimeContext) throws -> GRPHValue {
        property.value
    }
}

// These could return types directly in a future version

extension ValueTypeExpression: RunnableExpression {
    func eval(context: RuntimeContext) throws -> GRPHValue {
        try GRPHTypes.realType(of: on.evalIfRunnable(context: context), expected: nil).string
    }
}

extension TypeValueExpression: RunnableExpression {
    func eval(context: RuntimeContext) throws -> GRPHValue {
        type.string
    }
}
