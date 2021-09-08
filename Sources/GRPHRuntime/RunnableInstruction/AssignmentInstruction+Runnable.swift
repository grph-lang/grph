//
//  AssignmentInstruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation
import GRPHValues

extension AssignmentInstruction: RunnableInstruction {
    func run(context: inout RuntimeContext) throws {
        var cache = [GRPHValue]()
        guard let assigned = assigned as? RunnableAssignableExpression else {
            throw GRPHRuntimeError(type: .unexpected, message: "Expression of type \(type(of: assigned)) (line \(line)) has no assignable runnable implementation")
        }
        context = VirtualAssignmentRuntimeContext(parent: context, virtualValue: try assigned.eval(context: context, cache: &cache))
        let val = try value.evalIfRunnable(context: context)
        try assigned.assign(context: context, value: val, cache: &cache)
    }
}

extension AssignmentInstruction.VirtualExpression: RunnableExpression {
    func eval(context: RuntimeContext) throws -> GRPHValue {
        (context as! VirtualAssignmentRuntimeContext).virtualValue
    }
}

protocol RunnableAssignableExpression: Expression {
    func eval(context: RuntimeContext, cache: inout [GRPHValue]) throws -> GRPHValue
    func assign(context: RuntimeContext, value: GRPHValue, cache: inout [GRPHValue]) throws
}
