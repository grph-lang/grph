//
//  ReflectNameSpace.swift
//  GRPH Runtime
//
//  Created by Emil Pedersen on 18/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues

extension ReflectNameSpace: ImplementedNameSpace {
    
    func registerImplementations(reg: NativeFunctionRegistry) throws {
        reg.implement(function: exportedFunctions[named: "callFunction"]) { context, params in
            guard let ns = params.count == 1 || params[1] == nil || (params.count & 1) == 1 ? NameSpaces.none : NameSpaces.namespace(named: params[1] as! String) else {
                throw GRPHRuntimeError(type: .reflection, message: "Namespace '\(params[1]!)' not found")
            }
            guard let f = Function(imports: context.runtime.imports, namespace: ns, name: params[0] as! String) else {
                throw GRPHRuntimeError(type: .reflection, message: "Function '\(params[0]!)' not found in namespace '\(ns.name)'")
            }
            if params.count <= 2 {
                guard f.parameters.allSatisfy({ $0.optional }) else {
                    throw GRPHRuntimeError(type: .reflection, message: "Function '\(f.name)' requires arguments")
                }
                return try f.execute(context: context, arguments: [])
            }
            // ["name" "ns" "param1" value1] -- params.count == 4 -- drop 2
            // ["name" "param1" value1] -- 3 -- drop 1
            return try f.execute(context: context, arguments: f.labelled(values: params.dropFirst(2 - (params.count & 1)).map { $0! }))
        }
        reg.implement(function: exportedFunctions[named: "callFunctionAsync"]) { context, params in
            let f: Parametrable
            if let name = params[0] as? String {
                guard let fn = Function(imports: context.runtime.imports, namespace: NameSpaces.none, name: name) else {
                    throw GRPHRuntimeError(type: .reflection, message: "Local function '\(name)' not found")
                }
                f = fn
            } else if let funcref = params[0] as? FuncRef {
                f = funcref.currentType
            } else {
                throw GRPHRuntimeError(type: .invalidArgument, message: "First argument must be a string or a funcref")
            }
            
            let params = try f.labelled(values: params.dropFirst(2 - (params.count & 1)).map { $0! })
            
            let queue = DispatchQueue(label: "GRPH-Async")
            queue.async {
                do {
                    if let funcref = params[0] as? FuncRef {
                        _ = try funcref.execute(context: context, params: params)
                    } else {
                        _ = try (f as! Function).execute(context: context, arguments: params)
                    }
                } catch let e as GRPHRuntimeError {
                    context.runtime.image.destroy()
                    printerr("GRPH exited because of an unhandled exception in an async function")
                    printerr("\(e.type.rawValue)Exception: \(e.message)")
                    e.stack.forEach { printerr($0) }
                } catch is GRPHExecutionTerminated {
                    // ignore
                } catch let e {
                    printerr("Async function exited because of an unknown native error")
                    printerr("\(e)")
                }
            }
            return GRPHVoid.void
        }
        reg.implement(function: exportedFunctions[named: "callFuncref"]) { context, params in
            let funcref = params[0] as! FuncRef
            guard funcref.currentType.parameterTypes.count == params.count - 1 else {
                throw GRPHRuntimeError(type: .reflection, message: "Funcref '\(funcref.funcName)' of type '\(funcref.currentType.string)' expected \(funcref.currentType.parameterTypes.count) arguments; \(params.count - 1) were given")
            }
            return try funcref.execute(context: context, params: Array(params.dropFirst()))
        }
        reg.implement(function: exportedFunctions[named: "callMethod"]) { context, params in
            guard let ns = NameSpaces.namespace(named: params[1] as! String) else {
                throw GRPHRuntimeError(type: .reflection, message: "Namespace '\(params[1]!)' not found")
            }
            let value = params[2]!
            let valueType = GRPHTypes.type(of: value)
            guard let f = Method(imports: context.imports, namespace: ns, name: params[0] as! String, inType: valueType) else {
                throw GRPHRuntimeError(type: .reflection, message: "Function '\(params[0]!)' not found in namespace '\(ns.name)'")
            }
            return try f.execute(context: context, on: value, arguments: f.labelled(values: params.dropFirst(3).map { $0! }))
        }
        reg.implement(function: exportedFunctions[named: "callConstructor"]) { context, params in
            guard let type = GRPHTypes.parse(context: context, literal: params[0] as! String) else {
                throw GRPHRuntimeError(type: .reflection, message: "Type '\(params[0]!)' not found")
            }
            guard let f = type.constructor else {
                throw GRPHRuntimeError(type: .reflection, message: "Type '\(type.string)' has no constructor")
            }
            return try f.execute(context: context, arguments: f.labelled(values: params.dropFirst(1).map { $0! }))
        }
        reg.implement(function: exportedFunctions[named: "castTo"]) { context, params in
            guard let type = GRPHTypes.parse(context: context, literal: params[0] as! String) else {
                throw GRPHRuntimeError(type: .reflection, message: "Type '\(params[0]!)' not found")
            }
            let ab = try GRPHTypes.autobox(value: params[1]!, expected: type)
            if let value = CastExpression.cast(value: ab, to: type) {
                return value
            }
            throw GRPHRuntimeError(type: .reflection, message: "Impossible cast from '\(GRPHTypes.type(of: ab).string)' to '\(type.string)'")
        }
        reg.implement(function: exportedFunctions[named: "getVersion"]) { context, params in
            if let v = RequiresInstruction.currentVersion(plugin: params[safe: 0] as? String ?? "GRPH") {
                return v.description
            }
            throw GRPHRuntimeError(type: .reflection, message: "Unknown plugin '\(params[0]!)'")
        }
        reg.implement(function: exportedFunctions[named: "hasVersion"]) { context, params in
            if let v = RequiresInstruction.currentVersion(plugin: params[0] as! String) {
                if let q = params[1] as? String,
                   let query = Version(description: q) {
                    return v >= query
                } else {
                    return true
                }
            }
            return false
        }
        reg.implement(function: exportedFunctions[named: "getType"]) { context, params in
            GRPHTypes.type(of: params[0]!).string
        }
        reg.implement(function: exportedFunctions[named: "getDeclaredType"]) { context, params in
            guard let v = context.findVariable(named: params[0] as! String) else {
                throw GRPHRuntimeError(type: .reflection, message: "Undeclared variable '\(params[0]!)' in getDeclaredType.")
            }
            return v.type.string
        }
        reg.implement(function: exportedFunctions[named: "getVarValue"]) { context, params in
            guard let v = context.findVariable(named: params[0] as! String) else {
                throw GRPHRuntimeError(type: .reflection, message: "Undeclared variable '\(params[0]!)' in getVarValue.")
            }
            return v.content!
        }
        reg.implement(function: exportedFunctions[named: "isVarFinal"]) { context, params in
            guard let v = context.findVariable(named: params[0] as! String) else {
                throw GRPHRuntimeError(type: .reflection, message: "Undeclared variable '\(params[0]!)' in isVarFinal.")
            }
            return v.final
        }
        reg.implement(function: exportedFunctions[named: "isVarDeclared"]) { context, params in
            return context.findVariable(named: params[0] as! String) != nil
        }
        reg.implement(function: exportedFunctions[named: "declareVar"]) { context, params in
            let name = params[0] as! String
            let global = params[1] as? Bool ?? false
            guard context.findVariableInScope(named: name) == nil else {
                throw GRPHRuntimeError(type: .reflection, message: "Invalid redeclaration of variable '\(name)'")
            }
            guard let type = GRPHTypes.parse(context: context, literal: params[2] as! String) else {
                throw GRPHRuntimeError(type: .reflection, message: "Type '\(params[2]!)' not found")
            }
            let value = try GRPHTypes.autobox(value: params[3]!, expected: type)
            let assigned = GRPHTypes.type(of: value, expected: type)
            guard assigned.isInstance(of: type) else {
                throw GRPHRuntimeError(type: .reflection, message: "Incompatible types, cannot assign a '\(assigned)' to a variable of type '\(type)'")
            }
            context.addVariable(Variable(name: name, type: type, content: value, final: false), global: global)
            return GRPHVoid.void
        }
        reg.implement(function: exportedFunctions[named: "setVarValue"]) { context, params in
            guard let v = context.findVariable(named: params[0] as! String) else {
                throw GRPHRuntimeError(type: .reflection, message: "Undeclared variable '\(params[0]!)' in setVarValue.")
            }
            guard !v.final else {
                throw GRPHRuntimeError(type: .reflection, message: "Variable is final")
            }
            let value = try GRPHTypes.autobox(value: params[1]!, expected: v.type)
            let assigned = GRPHTypes.type(of: value, expected: v.type)
            guard assigned.isInstance(of: v.type) else {
                throw GRPHRuntimeError(type: .reflection, message: "Incompatible types, cannot assign a '\(assigned)' to a variable of type '\(v.type)'")
            }
            try v.setContent(value)
            return GRPHVoid.void
        }
        reg.implement(function: exportedFunctions[named: "getLambdaCaptureList"]) { context, params in
            let funcref = params[0] as! FuncRef
            switch funcref.storage {
            case .function(_, argumentGrid: _), .constant(_):
                return GRPHArray(of: SimpleType.string)
            case .lambda(_, capture: let capture):
                return GRPHArray(capture.map { $0.name }, of: SimpleType.string)
            }
        }
        reg.implement(function: exportedFunctions[named: "getLambdaCapturedVar"]) { context, params in
            let funcref = params[0] as! FuncRef
            switch funcref.storage {
            case .function(_, argumentGrid: _):
                throw GRPHRuntimeError(type: .reflection, message: "Funcref is a function reference, not a lambda")
            case .constant(_):
                throw GRPHRuntimeError(type: .reflection, message: "Funcref is a constant expression, not a lambda")
            case .lambda(let lambda, capture: let capture):
                guard let v = capture.first(where: { $0.name == params[1] as! String }) else {
                    throw GRPHRuntimeError(type: .reflection, message: "Variable '\(params[1]!)' was not captured in lambda from line '\(lambda.line)'")
                }
                guard !v.final else {
                    throw GRPHRuntimeError(type: .reflection, message: "Variable is final")
                }
                let value = v.content!
                if let modify = params[safe: 2] {
                    let value = try GRPHTypes.autobox(value: modify, expected: v.type)
                    let assigned = GRPHTypes.type(of: value, expected: v.type)
                    guard assigned.isInstance(of: v.type) else {
                        throw GRPHRuntimeError(type: .reflection, message: "Incompatible types, cannot assign a '\(assigned)' to a variable of type '\(v.type)'")
                    }
                    try v.setContent(value)
                }
                return value
            }
        }
    }
}
