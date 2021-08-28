//
//  Notice.swift
//  GRPHLexer
//
//  Created by Emil Pedersen on 28/08/2021.
//

import Foundation

struct Notice {
    /// The token that has a problem
    var token: Token
    
    var severity: Severity
    
    var source: Source
    
    var message: String
}

extension Notice {
    func represent() -> String {
        var msg = token.literal.base + "\n"
        msg += String(repeating: " ", count: token.literal.base.distance(from: token.literal.base.startIndex, to: token.lineOffset))
        msg += String(repeating: "^", count: token.literal.count)
        msg += "\n\(severity): \(message)"
        return msg
    }
}

extension Notice {
    /// This enum is compatible with LSP's `DiagnosticSeverity`
    enum Severity: Int {
        case error = 1
        case warning
        case info
        case hint
    }
}

extension Notice {
    enum Source: String {
        case lexer
        case tokenDetector
        case generator
    }
}
