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
    /// Output parsed tokens (CST). Runs Lexing and Token Detection, then exits.
    case parse
    /// Output WDIU (I&E/AST as code). Runs lexing, token detection, generation, and optionally DocGen, then exits.
    case wdiu
    /// Output AST (I&E as a syntax tree). Runs lexing, token detection, generation, and optionally DocGen, then exits.
    case ast
    /// Output nothing. Only check if compilation works. Runs lexing, token detection, generation, and optionally DocGen, then exits.
    case check
    
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

extension CompileDestination {
    
    init?(outputFile: String) {
        let ext = (outputFile as NSString).pathExtension
        switch ext {
        case "ll":
            self = .ir
        case "bc":
            self = .bc
        case "s", "asm":
            self = .assembly
        case "o", "obj":
            self = .object
        default:
            return nil
        }
    }
    
    func defaultOutputFile(input: String) -> String {
        let base = (input as NSString).deletingPathExtension
        switch self {
        case .ir:
            return "\(base).ll"
        case .bc:
            return "\(base).bc"
        case .assembly:
            return "\(base).s"
        case .object:
            return "\(base).o"
        case .executable:
            #if os(Windows)
            return "a.exe"
            #else
            return "a.out"
            #endif
        case .parse, .wdiu, .ast, .check:
            preconditionFailure()
        }
    }
}
