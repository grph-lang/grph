//
//  LambdaCompilingContext.swift
//  Graphism
//
//  Created by Emil Pedersen on 26/08/2021.
//

import Foundation

/// This 'lambda' context is used for parsing lambdas. It captures used variables when they are looked up
class LambdaCompilingContext: VariableOwningCompilingContext {
    
    var capturedVarNames: Set<String> = []
    
    override func accepts(instruction: Instruction) throws {
        switch instruction {
        case is BlockInstruction:
            throw GRPHCompileError(type: .unsupported, message: "You cannot use a block instruction inside a lambda")
        case is VariableDeclarationInstruction:
            throw GRPHCompileError(type: .unsupported, message: "Declaring a variable in a lambda will do nothing")
        case is BreakInstruction, is ReturnInstruction:
            throw GRPHCompileError(type: .unsupported, message: "Breaking from a lambda is unsupported")
        case is ThrowInstruction, is AssignmentInstruction, is ExpressionInstruction, is ArrayModificationInstruction, is RequiresInstruction:
            break // allowed
        default:
            print("[ERROR IN COMPILER] It is unknown if a \(type(of: instruction)) should be allowed in a lambda")
        }
    }
    
    /// We capture variables that break out.
    override func findVariable(named name: String) -> Variable? {
        if let found = variables.first(where: { $0.name == name }) {
            return found
        }
        // captured
        capturedVarNames.insert(name)
        return parent!.findVariable(named: name)
    }
}
