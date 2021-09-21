//
//  SwitchCompilingContext.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 26/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public class SwitchCompilingContext: CompilingContext {
    public let compare: VariableExpression
    public var state: SwitchState = .first
    
    public init(parent: CompilingContext, compare: VariableExpression) {
        self.compare = compare
        super.init(compiler: parent.compiler, parent: parent)
    }
    
    public override func accepts(instruction: Instruction) throws {
        guard instruction is IfBlock
           || instruction is ElseIfBlock
           || instruction is ElseBlock else {
            throw GRPHCompileError(type: .parse, message: "Expected #case or #default in #switch block")
        }
    }
    
    public enum SwitchState {
        /// Put an #if
        case first
        /// Put an #elseif or an #else
        case next
        /// Throw an error, no more cases can be added
        case last
    }
}
