//
//  FunctionDeclarationBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 14/07/2020.
//

import Foundation
import GRPHValues

extension FunctionDeclarationBlock: RunnableBlockInstruction {
    func createContext(_ context: inout RuntimeContext) -> BlockRuntimeContext {
        let ctx = FunctionRuntimeContext(parent: context, function: self)
        context = ctx
        return ctx
    }
    
    func executeFunction(context: RuntimeContext, params: [GRPHValue?]) throws -> GRPHValue {
        do {
            let ctx = FunctionRuntimeContext(parent: context, function: self)
            try parseParameters(context: ctx, params: params)
            try runChildren(context: ctx)
            if let returning = ctx.currentReturnValue {
                return returning
            } else if let returning = returnDefault {
                return try returning.evalIfRunnable(context: ctx)
            } else if generated.returnType.isTheVoid {
                return GRPHVoid.void
            } else {
                throw GRPHRuntimeError(type: .unexpected, message: "No #return value nor default value in non-void function")
            }
        } catch var exception as GRPHRuntimeError {
            exception.stack.append("\tat \(type(of: self)); line \(line)")
            throw exception
        }
    }
    
    func parseParameters(context: FunctionRuntimeContext, params: [GRPHValue?]) throws {
        var varargs: GRPHArray? = nil
        for i in 0..<params.count {
            let val = params[i]
            let p = generated.parameter(index: i)
            if generated.varargs && i >= generated.parameters.count - 1 {
                if varargs == nil {
                    varargs = GRPHArray(of: p.type)
                    context.variables.append(Variable(name: p.name, type: p.type.inArray, content: varargs, final: false))
                }
                varargs!.wrapped.append(val!)
            } else if p.optional {
                if let def = defaults[i] {
                    if val == nil {
                        context.variables.append(Variable(name: p.name, type: p.type, content: try def.evalIfRunnable(context: context), final: false))
                    } else {
                        context.variables.append(Variable(name: p.name, type: p.type, content: val, final: false))
                    }
                } else {
                    context.variables.append(Variable(name: p.name, type: p.type.optional, content: GRPHOptional(val), final: false))
                }
            } else {
                context.variables.append(Variable(name: p.name, type: p.type, content: val, final: false))
            }
        }
        // Optional trailing parameters
        if params.count < generated.parameters.count {
            for i in params.count..<generated.parameters.count {
                let p = generated.parameter(index: i)
                if let def = defaults[i] {
                    context.variables.append(Variable(name: p.name, type: p.type, content: try def.evalIfRunnable(context: context), final: false))
                } else {
                    context.variables.append(Variable(name: p.name, type: p.type.optional, content: GRPHOptional.null, final: false))
                }
            }
        }
    }
    
    func canRun(context: BlockRuntimeContext) throws -> Bool { false }
}
