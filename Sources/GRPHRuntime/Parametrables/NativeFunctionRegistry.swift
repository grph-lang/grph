//
//  NativeFunctionRegistry.swift
//  GRPH Runtime
//
//  Created by Emil Pedersen on 02/09/202.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues

class NativeFunctionRegistry {
    static let shared = NativeFunctionRegistry()
    
    private init() {
        do {
            try NameSpaces.registerAllImplementations(reg: self)
        } catch {
            printerr("Registering native implementations failed")
            printerr("\(error)")
        }
    }
    
    /// Note: We could use an actor, but this is only a workaround: Normally, everything should be added on the same thread, before anything is run.
    let queue = DispatchQueue(label: "NativeFunctionRegistry")
    
    private var constructors: [String: (GRPHType, RuntimeContext, [GRPHValue?]) -> GRPHValue] = [:]
    private var functions: [String: (RuntimeContext, [GRPHValue?]) throws -> GRPHValue] = [:]
    private var methods: [String: (RuntimeContext, GRPHValue, [GRPHValue?]) throws -> GRPHValue] = [:]
    
    func ensureRegistered() {
    }
    
    func implementation(for function: Function) throws -> ((RuntimeContext, [GRPHValue?]) throws -> GRPHValue) {
        ensureRegistered()
        guard let imp = functions[function.signature] else {
            throw GRPHRuntimeError(type: .unexpected, message: "No implementation found for native function '\(function.signature)'")
        }
        return imp
    }
    
    func implement(function: Function, with imp: @escaping (RuntimeContext, [GRPHValue?]) throws -> GRPHValue) {
        implement(functionWithSignature: function.signature, with: imp)
    }
    
    func implement(functionWithSignature signature: String, with imp: @escaping (RuntimeContext, [GRPHValue?]) throws -> GRPHValue) {
//        assert(functions[signature] == nil, "replacing native implementation for the already defined function '\(signature)'")
        queue.sync {
            functions[signature] = imp
        }
    }
    
    func implementation(for method: Method) throws -> ((RuntimeContext, GRPHValue, [GRPHValue?]) throws -> GRPHValue) {
        ensureRegistered()
        guard let imp = methods[method.signature] else {
            throw GRPHRuntimeError(type: .unexpected, message: "No implementation found for native method '\(method.signature)'")
        }
        return imp
    }
    
    func implementation(forMethodWithGenericSignature signature: String) throws -> ((RuntimeContext, GRPHValue, [GRPHValue?]) throws -> GRPHValue) {
        ensureRegistered()
        guard let imp = methods[signature] else {
            throw GRPHRuntimeError(type: .unexpected, message: "No implementation found for native generic method '\(signature)'")
        }
        return imp
    }
    
    func implement(method: Method, with imp: @escaping (RuntimeContext, GRPHValue, [GRPHValue?]) throws -> GRPHValue) {
        implement(methodWithSignature: method.signature, with: imp)
    }
    
    func implement(methodWithSignature signature: String, with imp: @escaping (RuntimeContext, GRPHValue, [GRPHValue?]) throws -> GRPHValue) {
//        assert(methods[signature] == nil, "replacing native implementation for the already defined method '\(signature)'")
        queue.sync {
            methods[signature] = imp
        }
    }
    
    func implementation(for constructor: Constructor) -> ((GRPHType, RuntimeContext, [GRPHValue?]) -> GRPHValue) {
        ensureRegistered()
        let signature: String
        switch constructor.storage {
        case .native:
            signature = constructor.signature
        case .generic(signature: let sig):
            signature = sig
        }
        guard let imp = constructors[signature] else {
            fatalError("No implementation found for constructor '\(signature)'")
        }
        return imp
    }
    
    func implement(constructor: Constructor, with imp: @escaping (GRPHType, RuntimeContext, [GRPHValue?]) -> GRPHValue) {
        implement(constructorWithSignature: constructor.signature, with: imp)
    }
    
    func implement(constructorWithSignature signature: String, with imp: @escaping (GRPHType, RuntimeContext, [GRPHValue?]) -> GRPHValue) {
//        assert(constructors[signature] == nil, "replacing native implementation for the already defined constructor '\(signature)'")
        queue.sync {
            constructors[signature] = imp
        }
    }
}
