//
//  BlockInstruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

/// The #block instruction, but also the base class for all other blocks
protocol BlockInstruction: Instruction {
    var children: [Instruction] { get set }
    var label: String? { get set }
    
    @discardableResult func createContext(_ context: inout CompilingContext) -> BlockCompilingContext
    
    var name: String { get }
}

extension BlockInstruction {
    func toString(indent: String) -> String {
        var builder = "\(line):\(indent)#\(name)\n"
        if let label = label {
            builder = "\(line - 1):\(indent)::\(label)\n\(builder)"
        }
        for child in children {
            builder += child.toString(indent: "\(indent)\t")
        }
        return builder
    }
    
    @discardableResult func createContext(_ context: inout CompilingContext) -> BlockCompilingContext {
        let ctx = BlockCompilingContext(compiler: context.compiler, parent: context)
        context = ctx
        return ctx
    }
}

struct SimpleBlockInstruction: BlockInstruction {
    let lineNumber: Int
    var children: [Instruction] = []
    var label: String?
    
    init(context: inout CompilingContext, lineNumber: Int) {
        self.lineNumber = lineNumber
        createContext(&context)
    }
    
    var name: String { "block" }
}
