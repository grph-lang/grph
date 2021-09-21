//
//  InputOutputNameSpace.swift
//  GRPH Runtime
//
//  Created by Emil Pedersen on 12/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues

extension InputOutputNameSpace: ImplementedNameSpace {
    
    func registerImplementations(reg: NativeFunctionRegistry) throws {
        reg.implement(function: exportedFunctions[named: "getLineInString"]) { ctx, params in
            let line = params[1] as! Int
            return String((params[0] as! String).split(separator: "\n", maxSplits: line + 1)[line])
        }
        reg.implement(function: exportedFunctions[named: "getLinesInString"]) { ctx, params in
            return GRPHArray((params[0] as! String).components(separatedBy: "\n"), of: SimpleType.string)
        }
        reg.implement(function: exportedFunctions[named: "getMousePos"]) { ctx, params in
            // TODO
            return GRPHOptional.null
        }
        reg.implement(function: exportedFunctions[named: "getTimeInMillisSinceLoad"]) { ctx, params in
            return Int(Date().timeIntervalSince(ctx.runtime.timestamp) * 1000)
        }
        reg.implement(function: exportedFunctions[named: "getSVGFromCurrentImage"]) { ctx, params in
            var svg: String = ""
            ctx.runtime.image.toSVG(context: SVGExportContext(), into: &svg)
            return svg
        }
    }
    
    static var isHeadless: Bool {
        #if GRAPHICAL
        return false // Graphical
        #else
        return true // CLI --> headless
        #endif
    }
}
