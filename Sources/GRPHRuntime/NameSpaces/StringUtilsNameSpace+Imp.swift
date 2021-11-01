//
//  StringUtilsNameSpace.swift
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

extension StringUtilsNameSpace: ImplementedNameSpace {
    
    func registerImplementations(reg: NativeFunctionRegistry) throws {
        reg.implement(function: exportedFunctions[named: "getStringLength"]) { ctx, params in
            return (params[0] as! String).count
        }
        reg.implement(function: exportedFunctions[named: "substring"]) { ctx, params in
            let subject = params[0] as! String
            let start = subject.index(subject.startIndex, offsetBy: params[1] as! Int)
            let end = params.count == 2 ? subject.endIndex : subject.index(subject.startIndex, offsetBy: params[2] as! Int)
            return String(subject[start..<end])
        }
        reg.implement(function: exportedFunctions[named: "indexInString"]) { ctx, params in
            let subject = params[0] as! String
            if let index = subject.range(of: params[1] as! String)?.lowerBound {
                return subject.distance(from: subject.startIndex, to: index)
            }
            return -1
        }
        reg.implement(function: exportedFunctions[named: "lastIndexInString"]) { ctx, params in
            let subject = params[0] as! String
            if let index = subject.range(of: params[1] as! String, options: .backwards)?.lowerBound {
                return subject.distance(from: subject.startIndex, to: index)
            }
            return -1
        }
        reg.implement(function: exportedFunctions[named: "stringContains"]) { ctx, params in
            return (params[0] as! String).contains(params[1] as! String)
        }
        reg.implement(function: exportedFunctions[named: "charToInteger"]) { ctx, params in
            if let scalar = (params[0] as! String).unicodeScalars.first {
                return Int(scalar.value)
            }
            throw GRPHRuntimeError(type: .invalidArgument, message: "Given string ins empty")
        }
        reg.implement(function: exportedFunctions[named: "integerToChar"]) { ctx, params in
            if let cp = UnicodeScalar(params[0] as! Int) {
                return String(cp)
            }
            return ""
        }
        reg.implement(function: exportedFunctions[named: "split"]) { ctx, params in
            return GRPHArray((params[0] as! String).components(separatedBy: params[1] as! String), of: SimpleType.string)
        }
        reg.implement(function: exportedFunctions[named: "joinStrings"]) { ctx, params in
            return (params[0] as! GRPHArray).wrapped.map { $0 as! String }.joined(separator: params.count == 1 ? "" : params[1] as! String)
        }
        reg.implement(function: exportedFunctions[named: "setStringLength"]) { ctx, params in
            let subject = params[0] as! String
            let length = params[1] as! Int
            if subject.count == length {
                return subject
            } else if subject.count >= length {
                return String(subject[subject.startIndex..<subject.index(subject.startIndex, offsetBy: length)])
            }
            let fill = params.count == 2 || (params[2] as! String).isEmpty ? " " : params[2] as! String
            let result = subject + String(repeating: fill, count: (length - subject.count - 1) / fill.count + 1)
            return String(result[result.startIndex..<result.index(result.startIndex, offsetBy: length)])
        }
    }
}
