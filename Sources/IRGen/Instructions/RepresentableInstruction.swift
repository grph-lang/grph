//
//  RepresentableInstruction.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 26/01/2022.
//  Copyright © 2022 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues

protocol RepresentableInstruction: Instruction {
    /// Builds an instruction into the given generator's builder
    ///
    /// Contract: Before an instruction is built and after it is built, the IRBuilder must be at the end of a non-terminated basic block.
    /// As such, it is always valid to build upon, even if it's into an unreachable basic block.
    func build(generator: IRGenerator) throws
}

extension Array where Element == Instruction {
    func buildAll(generator: IRGenerator) throws {
        for inst in self {
            if let inst = inst as? RepresentableInstruction {
                try inst.build(generator: generator)
            } else {
                throw GRPHCompileError(type: .unsupported, message: "Instruction of type \(type(of: inst)) is not supported in IRGen mode")
            }
        }
    }
}
