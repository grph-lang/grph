//
//  SwitchCompilingContext.swift
//  Graphism
//
//  Created by Emil Pedersen on 26/07/2020.
//

import Foundation

class SwitchCompilingContext: CompilingContext {
    let compare: VariableExpression
    var state: SwitchState = .first
    
    init(parent: CompilingContext, compare: VariableExpression) {
        self.compare = compare
        super.init(compiler: parent.compiler, parent: parent)
    }
    
    override func accepts(instruction: Instruction) throws {
        guard instruction is IfBlock
           || instruction is ElseIfBlock
           || instruction is ElseBlock else {
            throw GRPHCompileError(type: .parse, message: "Expected #case or #default in #switch block")
        }
    }
    
    enum SwitchState {
        /// Put an #if
        case first
        /// Put an #elseif or an #else
        case next
        /// Throw an error, no more cases can be added
        case last
    }
}
