//
//  ArrayModificationInstruction.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 07/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public final class ArrayModificationInstruction: Instruction {
    public let lineNumber: Int
    public let name: String
    public let op: ArrayModificationOperation
    public let index: Expression?
    public let value: Expression?
    
    public init(lineNumber: Int, name: String, op: ArrayModificationOperation, index: Expression?, value: Expression?) throws {
        self.lineNumber = lineNumber
        self.name = name
        self.op = op
        self.value = value
        self.index = index
        
        if op == .set && index == nil {
            throw GRPHCompileError(type: .invalidArguments, message: "Index or operation required in array modification instruction")
        }
        if op != .remove && value == nil {
            throw GRPHCompileError(type: .invalidArguments, message: "Value required in array modification instruction")
        }
        if op == .remove && index == nil && value == nil {
            throw GRPHCompileError(type: .invalidArguments, message: "Value or index required in array modification instruction")
        }
    }
    
    public convenience init(lineNumber: Int, context: CompilingContext, name: String, op: ArrayModificationOperation, index: Expression?, value: Expression?) throws {
        
        if let index = index {
            guard SimpleType.integer.isInstance(context: context, expression: index) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Expected integer in array modification index")
            }
        }
        guard let v = context.findVariable(named: name) else {
            throw GRPHCompileError(type: .undeclared, message: "Undeclared variable '\(name)'")
        }
        guard let arr = v.type as? ArrayType else {
            throw GRPHCompileError(type: .typeMismatch, message: "Expected an array in array modification, got a \(v.type)")
        }
        if let exp = value {
            guard arr.content.isInstance(context: context, expression: exp) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Expected \(arr.content) as array content, got \(exp.getType())")
            }
        }
        
        try self.init(lineNumber: lineNumber, name: name, op: op, index: index, value: value)
    }
    
    public func toString(indent: String) -> String {
        "\(line):\(indent)\(name){\(index?.string ?? "")\(op.rawValue)} = \(value?.string ?? "")\n"
    }
    
    public enum ArrayModificationOperation: String {
        case set = ""
        case add = "+"
        case remove = "-"
    }
}

public extension ArrayModificationInstruction {
    var astNodeData: String {
        switch op {
        case .set:
            return "modify element in array \(name)"
        case .add:
            return "add element to array \(name)"
        case .remove:
            return "remove element from array \(name)"
        }
    }
    
    var astChildren: [ASTElement] {
        [
            ASTElement(name: "index", value: index),
            ASTElement(name: "value", value: value),
        ]
    }
}
