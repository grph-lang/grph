//
//  ArrayModificationInstruction.swift
//  GRPH Runtime
//
//  Created by Emil Pedersen on 07/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues

extension ArrayModificationInstruction: RunnableInstruction {
    func run(context: inout RuntimeContext) throws {
        guard let v = context.findVariable(named: name) else {
            throw GRPHRuntimeError(type: .unexpected, message: "Undeclared variable '\(name)'")
        }
        let val = try value?.evalIfRunnable(context: context)
        guard let arr = v.content! as? GRPHArray else { // No autoboxing here (consistency with Java version)
            throw GRPHRuntimeError(type: .typeMismatch, message: "Expected an array in array modification, got a \(GRPHTypes.realType(of: v.content!, expected: nil))")
        }
        switch op {
        case .set:
            guard let index = try index?.evalIfRunnable(context: context) as? Int,
                  index < arr.count else {
                throw GRPHRuntimeError(type: .unexpected, message: "Invalid index")
            }
            arr.wrapped[index] = val!
        case .add:
            if let index = try index?.evalIfRunnable(context: context) as? Int {
                guard index <= arr.count else {
                    throw GRPHRuntimeError(type: .unexpected, message: "Invalid index \(index) in insertion for array of length \(arr.count)")
                }
                arr.wrapped.insert(val!, at: index)
            } else {
                arr.wrapped.append(val!)
            }
        case .remove:
            if let index = try index?.evalIfRunnable(context: context) as? Int {
                guard index < arr.count else {
                    throw GRPHRuntimeError(type: .unexpected, message: "Invalid index \(index) in insertion for array of length \(arr.count)")
                }
                if let val = val {
                    if arr.wrapped[index].isEqual(to: val) {
                        arr.wrapped.remove(at: index)
                    }
                } else {
                    arr.wrapped.remove(at: index)
                }
            } else if let val = val,
                      let index = arr.wrapped.firstIndex(where: { $0.isEqual(to: val) }) {
                arr.wrapped.remove(at: index)
            }
        }
        if context.runtime.debugging {
            printout("[DEBUG VAR \(v.name)=\(v.content!)]")
        }
    }
}
