//
//  MathNameSpace.swift
//  GRPH Runtime
//
//  Created by Emil Pedersen on 13/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues

extension MathNameSpace: ImplementedNameSpace {
    func registerImplementations(reg: NativeFunctionRegistry) throws {
        reg.implement(function: exportedFunctions[named: "sum"]) { ctx, params in
            return params.map { $0 as? Float ?? Float($0 as! Int) }.reduce(into: 0 as Float) { $0 += $1 }
        }
        reg.implement(function: exportedFunctions[named: "difference"]) { ctx, params in
            let params = params.map { $0 as? Float ?? Float($0 as! Int) }
            return params.dropFirst().reduce(into: params[0]) { $0 -= $1 }
        }
        reg.implement(function: exportedFunctions[named: "multiply"]) { ctx, params in
            return params.map { $0 as? Float ?? Float($0 as! Int) }.reduce(into: 1 as Float) { $0 *= $1 }
        }
        reg.implement(function: exportedFunctions[named: "divide"]) { ctx, params in
            let params = params.map { $0 as? Float ?? Float($0 as! Int) }
            return params.dropFirst().reduce(into: params[0]) { $0 /= $1 }
        }
        reg.implement(function: exportedFunctions[named: "modulo"]) { ctx, params in
            let params = params.map { $0 as? Float ?? Float($0 as! Int) }
            return params.dropFirst().reduce(into: params[0]) { $0 = fmodf($0, $1) }
        }
        reg.implement(function: exportedFunctions[named: "sqrt"]) { ctx, params in
            return sqrt(params[0] as? Float ?? Float(params[0] as! Int))
        }
        reg.implement(function: exportedFunctions[named: "cbrt"]) { ctx, params in
            return cbrt(params[0] as? Float ?? Float(params[0] as! Int))
        }
        reg.implement(function: exportedFunctions[named: "pow"]) { ctx, params in
            return pow(params[0] as? Float ?? Float(params[0] as! Int), params[1] as? Float ?? Float(params[1] as! Int))
        }
        reg.implement(function: exportedFunctions[named: "PI"]) { ctx, params in
            return Float.pi
        }
        reg.implement(function: exportedFunctions[named: "round"]) { ctx, params in
            return Int(round(params[0] as? Float ?? Float(params[0] as! Int)))
        }
        reg.implement(function: exportedFunctions[named: "floor"]) { ctx, params in
            return Int(floor(params[0] as? Float ?? Float(params[0] as! Int)))
        }
        reg.implement(function: exportedFunctions[named: "ceil"]) { ctx, params in
            return Int(ceil(params[0] as? Float ?? Float(params[0] as! Int)))
        } // asFloat is a cast, asChar is in strutils --> Removed
        reg.implement(function: exportedFunctions[named: "min"]) { ctx, params in
            let params = params.map { $0 as? Float ?? Float($0 as! Int) }
            return params.min() ?? Float.infinity
        }
        reg.implement(function: exportedFunctions[named: "max"]) { ctx, params in
            let params = params.map { $0 as? Float ?? Float($0 as! Int) }
            return params.max() ?? -Float.infinity
        }
    }
}
