//
//  GRPHContextProtocol.swift
//  Graphism
//
//  Created by Emil Pedersen on 01/09/2021.
//

import Foundation

protocol GRPHContextProtocol: AnyObject {
    var imports: [Importable] { get }
}

protocol GRPHCompilerProtocol: AnyObject {
    var imports: [Importable] { get set }
    var hasStrictUnboxing: Bool { get }
    var hasStrictBoxing: Bool { get }
    
    var lineNumber: Int { get }
    var context: CompilingContext! { get set }
}

struct GRPHCompileError: Error {
    var type: CompileErrorType
    var message: String
    
    enum CompileErrorType: String {
        case parse = "Parse"
        case typeMismatch = "Type"
        case undeclared = "Undeclared"
        case redeclaration = "Redeclaration"
        case invalidArguments = "InvalidArguments"
        case unsupported = "Unsupported"
    }
}

struct GRPHRuntimeError: Error {
    var type: RuntimeExceptionType
    var message: String
    var stack: [String] = []
    
    enum RuntimeExceptionType: String {
        case typeMismatch = "InvalidType"
        case cast = "Cast"
        case inputOutput = "IO"
        case unexpected = "Unexpected"
        case reflection = "Reflection"
        case invalidArgument = "InvalidArgument"
        case permission = "NoPermission"
    }
}
