//
//  FunctionExpression.swift
//  GRPH Runtime
//
//  Created by Emil Pedersen on 05/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues

extension ConstructorExpression: RunnableExpression {
    func eval(context: RuntimeContext) throws -> GRPHValue {
        return constructor.execute(context: context, arguments: try values.map { try $0?.evalIfRunnable(context: context) })
    }
}

extension FunctionExpression: RunnableExpression {
    func eval(context: RuntimeContext) throws -> GRPHValue {
        do {
            return try function.execute(context: context, arguments: try values.map { try $0?.evalIfRunnable(context: context) })
        } catch var e as GRPHRuntimeError {
            e.stack.append("\tat \(function.fullyQualifiedName)")
            throw e
        }
    }
}

extension MethodExpression: RunnableExpression {
    func eval(context: RuntimeContext) throws -> GRPHValue {
        let onValue = try on.evalIfRunnable(context: context)
        var m = method
        if !m.effectivelyFinal { // check for overrides
            let real = GRPHTypes.type(of: onValue, expected: m.inType)
            m = Method(imports: context.imports, namespace: NameSpaces.none, name: m.name, inType: real) ?? m
        }
        do {
            return try m.execute(context: context, on: onValue, arguments: try values.map { try $0?.evalIfRunnable(context: context) })
        } catch var e as GRPHRuntimeError {
            e.stack.append("\tat \(fullyQualified)")
            throw e
        }
    }
}

extension FuncRefCallExpression: RunnableExpression {
    func eval(context: RuntimeContext) throws -> GRPHValue {
        guard let variable = context.findVariable(named: varName) else {
            throw GRPHRuntimeError(type: .invalidArgument, message: "Unknown variable '\(varName)'")
        }
        
        guard let funcref = variable.content as? FuncRef else {
            throw GRPHRuntimeError(type: .typeMismatch, message: "Funcref call on non-funcref value")
        }
        
        do {
            return try funcref.execute(context: context, params: try values.map { try $0?.evalIfRunnable(context: context) })
        } catch var e as GRPHRuntimeError {
            e.stack.append("\tat \(funcref.funcName) in funcref \(varName)")
            throw e
        }
    }
}
