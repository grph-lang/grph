//
//  AssignmentInstruction.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 05/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public final class AssignmentInstruction: Instruction {
    public let lineNumber: Int
    public let assigned: AssignableExpression
    public let value: Expression
    public let virtualized: Bool
    
    public init(lineNumber: Int, context: CompilingContext, assigned: AssignableExpression, op: String?, value: Expression) throws {
        self.lineNumber = lineNumber
        self.assigned = assigned
        
        let varType = assigned.getType()
        let avalue = try GRPHTypes.autobox(context: context, expression: value, expected: varType)
        
        guard varType.isInstance(context: context, expression: avalue) else {
            throw GRPHCompileError(type: .typeMismatch, message: "Incompatible types '\(avalue.getType())' and '\(varType)' in assignment")
        }
        
        if let op = op {
            self.virtualized = true
            self.value = try BinaryExpression(context: context, left: VirtualExpression(type: assigned.getType()), op: op, right: avalue)
        } else {
            self.virtualized = false
            self.value = avalue
        }
        try assigned.checkCanAssign(context: context)
    }
    
    public func toString(indent: String) -> String {
        var op = ""
        var right = value
        if virtualized, let infix = value as? BinaryExpression {
            op = infix.op.string
            right = infix.right
        }
        return "\(line):\(indent)\(assigned) \(op)= \(right)\n"
    }
    
    public struct VirtualExpression: Expression {
        public let type: GRPHType
        
        public func getType() -> GRPHType {
            type
        }
        
        public var string: String { "$_virtual$" } // never called
        
        public var needsBrackets: Bool { false } // never called
    }
}

public protocol AssignableExpression: Expression {
    func checkCanAssign(context: CompilingContext) throws
}

public extension AssignmentInstruction.VirtualExpression {
    var astNodeData: String {
        "virtual expression of type \(type)"
    }
    
    var astChildren: [ASTElement] { [] }
}

public extension AssignmentInstruction {
    var astNodeData: String {
        "assign a value to another"
    }
    
    var astChildren: [ASTElement] {
        [
            ASTElement(name: "lvalue", value: [assigned]),
            ASTElement(name: "rvalue", value: [value]),
        ]
    }
}
