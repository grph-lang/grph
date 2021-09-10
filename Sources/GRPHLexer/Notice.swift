//
//  Notice.swift
//  GRPHLexer
//
//  Created by Emil Pedersen on 28/08/2021.
//

import Foundation

public struct Notice {
    /// The token that has a problem
    public var token: Token
    
    public var severity: Severity
    
    public var source: Source
    
    public var message: String
    
    public var hint: String?
    
    public init(token: Token, severity: Notice.Severity, source: Notice.Source, message: String, hint: String? = nil) {
        self.token = token
        self.severity = severity
        self.source = source
        self.message = message
        self.hint = hint
    }
}

public extension Notice {
    func represent() -> String {
        // remove tabs as they mess everything up with their wider size
        let base = token.literal.base
        var msg = base.replacingOccurrences(of: "\t", with: " ") + "\n"
        msg += String(repeating: " ", count: base.distance(from: base.startIndex, to: token.lineOffset))
        msg += String(repeating: "^", count: token.literal.count)
        msg += "\n\(severity): \(message)"
        if let hint = hint {
            msg += "\nhint: \(hint)"
        }
        return msg
    }
}

public extension Notice {
    /// This enum is compatible with LSP's `DiagnosticSeverity`
    enum Severity: Int {
        case error = 1
        case warning
        case info
        case hint
    }
}

public extension Notice {
    enum Source: String {
        /// This problem was catched by the base lexer
        case lexer
        /// This problem was catched by the token detector
        case tokenDetector
        /// This problem was catched by the generator
        case generator
        /// This problem was catched by the documentation generator
        case docgen
    }
}
