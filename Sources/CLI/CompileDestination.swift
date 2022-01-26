//
//  File.swift
//  GRPH
// 
//  Created by Emil Pedersen on 09/01/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import ArgumentParser

enum CompileDestination: String, CaseIterable, ExpressibleByArgument {
    /// Output AST. Runs Lexing and Token Detection, then exits.
    case ast
    /// Output WDIU/INE. Runs lexing, token detection, generation, and optionally DocGen, then exits.
    case wdiu
    /// Output nothing. Only check if compilation works. Runs lexing, token detection, generation, and optionally DocGen, then exits.
    case check
    
    /// Output raw, freshly generated, LLVM IR. Runs all phases.
    case irgen
    /// Output LLVM IR. Runs all phases.
    case ir
    /// Output LLVM bitcode. Runs all phases.
    case bc
    /// Output assembly. Runs all phases. (-S)
    case assembly
    /// Output an object file (.o/.obj). Runs all phases. (-c)
    case object
    /// Output an executable. Runs all phases. Links automatically with all needed libraries.
    case executable
}
