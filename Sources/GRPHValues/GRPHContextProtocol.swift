//
//  GRPHContextProtocol.swift
//  Graphism
//
//  Created by Emil Pedersen on 01/09/2021.
//

import Foundation

public protocol GRPHContextProtocol: AnyObject {
    var imports: [Importable] { get }
}

public protocol GRPHCompilerProtocol: AnyObject {
    var imports: [Importable] { get set }
    var hasStrictUnboxing: Bool { get }
    var hasStrictBoxing: Bool { get }
    
    var lineNumber: Int { get }
    var context: CompilingContext! { get set }
}

public struct GRPHCompileError: Error {
    public var type: CompileErrorType
    public var message: String
    
    public init(type: GRPHCompileError.CompileErrorType, message: String) {
        self.type = type
        self.message = message
    }
    
    public enum CompileErrorType: String {
        case parse = "Parse"
        case typeMismatch = "Type"
        case undeclared = "Undeclared"
        case redeclaration = "Redeclaration"
        case invalidArguments = "InvalidArguments"
        case unsupported = "Unsupported"
    }
}

public struct GRPHRuntimeError: Error {
    public var type: RuntimeExceptionType
    public var message: String
    public var stack: [String] = []
    
    public init(type: GRPHRuntimeError.RuntimeExceptionType, message: String) {
        self.type = type
        self.message = message
    }
    
    public enum RuntimeExceptionType: String {
        case typeMismatch = "InvalidType"
        case cast = "Cast"
        case inputOutput = "IO"
        case unexpected = "Unexpected"
        case reflection = "Reflection"
        case invalidArgument = "InvalidArgument"
        case permission = "NoPermission"
    }
}
