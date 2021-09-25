//
//  BlockInstruction.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 02/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

/// The #block instruction, but also the base class for all other blocks
public protocol BlockInstruction: Instruction {
    var children: [Instruction] { get set }
    var label: String? { get set }
    
    @discardableResult func createContext(_ context: inout CompilingContext) -> BlockCompilingContext
    
    var name: String { get }
}

public extension BlockInstruction {
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

public struct SimpleBlockInstruction: BlockInstruction {
    public let lineNumber: Int
    public var children: [Instruction] = []
    public var label: String?
    
    public init(compiler: GRPHCompilerProtocol, lineNumber: Int) {
        self.lineNumber = lineNumber
        createContext(&compiler.context)
    }
    
    public var name: String { "block" }
}
