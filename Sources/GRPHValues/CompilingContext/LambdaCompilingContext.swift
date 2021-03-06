//
//  LambdaCompilingContext.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 26/08/2021.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

/// This 'lambda' context is used for parsing lambdas. It captures used variables when they are looked up
public class LambdaCompilingContext: VariableOwningCompilingContext {
    
    public var capturedVarNames: Set<String> = []
    
    public override func accepts(instruction: Instruction) throws {
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
    public override func findVariable(named name: String) -> Variable? {
        if let found = variables.first(where: { $0.name == name }) {
            return found
        }
        // captured
        capturedVarNames.insert(name)
        return parent!.findVariable(named: name)
    }
}
