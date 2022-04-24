//
//  BreakInstruction.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 03/02/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues

extension BreakInstruction: RepresentableInstruction {
    func build(generator: IRGenerator) throws {
        guard let scope = generator.currentContext?.findBreak(scope: self.scope) else {
            throw GRPHCompileError(type: .invalidArguments, message: "Break destination could not be resolved")
        }
        // TODO: cleanup broken blocks
        switch self.type {
        case .break:
            generator.builder.buildBr(scope.breakDestination)
        case .continue:
            if let dest = scope.continueDestination {
                generator.builder.buildBr(dest)
            } else {
                print("Warning: line \(line): #continue in a non-loop has the same effect as a #break")
                generator.builder.buildBr(scope.breakDestination)
            }
        case .fall:
            if let dest = scope.fallDestination {
                generator.builder.buildBr(dest)
            } else {
                print("Warning: line \(line): #fall without an #else block has the same effect as a #break")
                generator.builder.buildBr(scope.breakDestination)
            }
        case .fallthrough:
            if let dest = scope.fallthroughDestination {
                generator.builder.buildBr(dest)
            } else {
                print("Warning: line \(line): #fallthrough without an #else block has the same effect as a #break")
                generator.builder.buildBr(scope.breakDestination)
            }
        }
        let next = generator.builder.currentFunction!.appendBasicBlock(named: "unreachable")
        generator.builder.positionAtEnd(of: next)
    }
}
