//
//  Lambda.swift
//  Lambda
//
//  Created by Emil Pedersen on 26/08/2021.
//

import Foundation
import GRPHValues

extension Lambda {
    func execute(context: RuntimeContext, params: [GRPHValue?], capture: [Variable]) throws -> GRPHValue {
        var ctx: RuntimeContext = LambdaRuntimeContext(runtime: context.runtime, parent: context)
        for (param, arg) in zip(parameters, params) {
            ctx.addVariable(Variable(name: param.name, type: param.type, content: arg, final: true), global: false)
        }
        for captured in capture {
            ctx.addVariable(captured, global: false)
        }
        if !currentType.returnType.isTheVoid,
           let expr = instruction as? ExpressionInstruction {
            return try expr.expression.evalIfRunnable(context: ctx)
        } else {
            guard let instruction = instruction as? RunnableInstruction else {
                throw GRPHRuntimeError(type: .unexpected, message: "Instruction of type \(type(of: instruction)) (in lambda) has no runnable implementation")
            }
            try instruction.safeRun(context: &ctx)
            return GRPHVoid.void
        }
    }
}
