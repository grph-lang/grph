//
//  Token+Rainbow.swift
//  grph
//
//  Created by Emil Pedersen on 09/09/2021.
//

import Foundation
import Rainbow
import GRPHLexer

extension Token {
    func dumpAST(indent: String = "") -> String {
        let head = "\(indent)\(literal.debugDescription.red) \(String(describing: tokenType).magenta) (\(lineNumber):\(lineOffset.utf16Offset(in: literal.base))) \(data.description.green)\n"
        
        return head + children.map { $0.dumpAST(indent: indent + "    ") }.joined()
    }
}

extension Notice.Severity {
    var colorfulDescription: String {
        let desc = String(describing: self)
        switch self {
        case .error:
            return desc.red
        case .warning:
            return desc.yellow
        case .info, .hint:
            return desc.blue
        }
    }
}

extension Notice {
    func representNicely() -> String {
        // remove tabs as they mess everything up with their wider size
        let base = token.literal.base
        var msg = base.replacingOccurrences(of: "\t", with: " ") + "\n"
        msg += String(repeating: " ", count: base.distance(from: base.startIndex, to: token.lineOffset))
        msg += String(repeating: "^", count: token.literal.count)
        msg += "\n\(severity.colorfulDescription): \(message)"
        if let hint = hint {
            msg += "\nhint: \(hint)"
        }
        return msg
    }
}
