//
//  FunctionDeclarationBlock.swift
//  Graphism
//
//  Created by Emil Pedersen on 14/07/2020.
//

import Foundation

class FunctionDeclarationBlock: BlockInstruction {
    let lineNumber: Int
    var children: [Instruction] = []
    var label: String?
    
    var generated: Function!
    var defaults: [Expression?] = []
    var returnDefault: Expression?
    
    init(lineNumber: Int, children: [Instruction] = [], label: String? = nil, generated: Function? = nil, defaults: [Expression?] = [], returnDefault: Expression? = nil) {
        self.lineNumber = lineNumber
        self.children = children
        self.label = label
        self.generated = generated
        self.defaults = defaults
        self.returnDefault = returnDefault
    }
    
    func createContext(_ context: inout CompilingContext) -> BlockCompilingContext {
        let ctx = FunctionCompilingContext(parent: context, function: self)
        context = ctx
        return ctx
    }
    
    var name: String {
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
}
