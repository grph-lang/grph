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
