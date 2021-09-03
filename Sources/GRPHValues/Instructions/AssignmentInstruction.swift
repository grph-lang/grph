//
//  AssignmentInstruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 05/07/2020.
//

import Foundation

public struct AssignmentInstruction: Instruction {
    public let lineNumber: Int
    public let assigned: AssignableExpression
    public let value: Expression
    public let virtualized: Bool
    
    public init(lineNumber: Int, context: CompilingContext, assigned: AssignableExpression, op: String?, value: Expression) throws {
        self.lineNumber = lineNumber
        self.assigned = assigned
        
        let varType = try assigned.getType(context: context, infer: SimpleType.mixed)
        let avalue = try GRPHTypes.autobox(context: context, expression: value, expected: varType)
        
        guard try varType.isInstance(context: context, expression: avalue) else {
            throw GRPHCompileError(type: .typeMismatch, message: "Incompatible types '\(try avalue.getType(context: context, infer: SimpleType.mixed))' and '\(varType)' in assignment")
        }
        
        if let op = op {
            self.virtualized = true
            self.value = try BinaryExpression(context: context, left: VirtualExpression(type: assigned.getType(context: context, infer: SimpleType.mixed)), op: op, right: avalue)
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
        
        public func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
            type
        }
        
        public var string: String { "$_virtual$" } // never called
        
        public var needsBrackets: Bool { false } // never called
    }
}

public protocol AssignableExpression: Expression {
    func checkCanAssign(context: CompilingContext) throws
}
