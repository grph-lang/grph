//
//  BreakInstruction.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/07/2020.
//

import Foundation

public struct BreakInstruction: Instruction {
    public let lineNumber: Int
    public let type: BreakType
    public let scope: BreakScope
    
    public init(lineNumber: Int, type: BreakInstruction.BreakType, scope: BreakInstruction.BreakScope) {
        self.lineNumber = lineNumber
        self.type = type
        self.scope = scope
    }
    
    public func toString(indent: String) -> String {
        return "\(line):\(indent)#\(type.rawValue) \(scope)\n"
    }
    
    public enum BreakType: String {
        case `break` = "break"
        case `continue` = "continue"
        case fall = "fall"
        case `fallthrough` = "fallthrough"
    }
    
    public enum BreakScope: CustomStringConvertible {
        case scopes(Int)
        case label(String)
        
        public static func parse(params: String) throws -> BreakScope {
            if params.hasPrefix("::") {
                return .label(String(params.dropFirst(2)))
            } else if let i = Int(params) {
                return .scopes(i)
            } else if params.isEmpty {
                return .scopes(1)
            } else {
                throw GRPHCompileError(type: .parse, message: "Break instruction expected a label or a number of scopes")
            }
        }
        
        public var description: String {
            switch self {
            case .scopes(let n):
                return "\(n)"
            case .label(let label):
                return "::\(label)"
            }
        }
    }
}

public struct ReturnInstruction: Instruction {
    public let lineNumber: Int
    public var value: Expression? = nil
    
    public init(lineNumber: Int, value: Expression? = nil) {
        self.lineNumber = lineNumber
        self.value = value
    }
    
    public func toString(indent: String) -> String {
        return "\(line):\(indent)#return \(value?.string ?? "")\n"
    }
}