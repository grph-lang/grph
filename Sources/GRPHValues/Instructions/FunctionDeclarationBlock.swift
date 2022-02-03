//
//  FunctionDeclarationBlock.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 14/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public final class FunctionDeclarationBlock: BlockInstruction {
    public let lineNumber: Int
    public var children: [Instruction] = []
    public var label: String?
    
    public var generated: Function!
    public var defaults: [Expression?] = []
    public var returnDefault: Expression?
    
    public init(lineNumber: Int, children: [Instruction] = [], label: String? = nil, generated: Function? = nil, defaults: [Expression?] = [], returnDefault: Expression? = nil) {
        self.lineNumber = lineNumber
        self.children = children
        self.label = label
        self.generated = generated
        self.defaults = defaults
        self.returnDefault = returnDefault
    }
    
    public func createContext(_ context: inout CompilingContext) -> BlockCompilingContext {
        let ctx = FunctionCompilingContext(parent: context, function: self)
        context = ctx
        return ctx
    }
    
    public var name: String {
        var str = "function \(generated.returnType.string) \(generated.name)["
        var i = 0
        generated.parameters.forEach { p in
            if i > 0 {
                str += ", "
            }
            str += "\(p.type) \(p.name)"
            if p.optional {
                if let value = defaults[i] {
                    str += " = \(value)"
                } else {
                    str += "?"
                }
            }
            i += 1
        }
        if generated.varargs {
            str += "..."
        }
        str += "]"
        if let returnDefault = returnDefault {
            str += " = \(returnDefault)"
        }
        return str
    }
    
    public var astNodeData: String {
        "declare function \(generated.signature)"
    }
    
    public var astChildren: [ASTElement] {
        [
            ASTElement(name: "defaultValues", value: defaults.compactMap({ $0 })),
            ASTElement(name: "defaultReturnValue", value: returnDefault),
            astBlockChildren
        ]
    }
}
