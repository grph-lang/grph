//
//  ArrayModificationInstruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 07/07/2020.
//

import Foundation

struct ArrayModificationInstruction: Instruction {
    let lineNumber: Int
    let name: String
    let op: ArrayModificationOperation
    let index: Expression?
    let value: Expression?
    
    init(lineNumber: Int, name: String, op: ArrayModificationOperation, index: Expression?, value: Expression?) throws {
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
    
    init(lineNumber: Int, context: CompilingContext, name: String, op: ArrayModificationOperation, index: Expression?, value: Expression?) throws {
        
        if let index = index {
            guard try SimpleType.integer.isInstance(context: context, expression: index) else {
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
            guard try arr.content.isInstance(context: context, expression: exp) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Expected \(arr.content) as array content, got \(try exp.getType(context: context, infer: arr.content))")
            }
        }
        
        try self.init(lineNumber: lineNumber, name: name, op: op, index: index, value: value)
    }
    
    func toString(indent: String) -> String {
        "\(line):\(indent)\(name){\(index?.string ?? "")\(op.rawValue)} = \(value?.string ?? "")\n"
    }
    
    enum ArrayModificationOperation: String {
        case set = ""
        case add = "+"
        case remove = "-"
    }
}
