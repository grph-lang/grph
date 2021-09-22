//
//  Token+Rainbow.swift
//  Graphism CLI
//
//  Created by Emil Pedersen on 09/09/2021.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import Rainbow
import GRPHLexer
import GRPHGenerator

extension Token {
    func dumpAST(indent: String = "") -> String {
        let head = "\(indent)\(literal.debugDescription.red) \(String(describing: tokenType).magenta) (\(lineNumber):\(lineOffset.utf16Offset(in: literal.base))) \(data.description.green)\n"
        
        return head + children.map { $0.dumpAST(indent: indent + "    ") }.joined()
    }
    
    // semantic tokens must all be on the correct line
    func highlighted(semanticTokens: [SemanticToken] = []) -> String {
        // matches are either exact same, or bigger
        if let match = semanticTokens.last(where: { sem in
            return sem.token.lineOffset <= self.lineOffset && self.literal.endIndex <= sem.token.literal.endIndex
        }) {
            return highlighted(content: description, type: match.token.tokenType, modifiers: match.modifiers)
        } else if children.isEmpty,
                  case let newChildren = semanticTokens.filter({ sem in
                      return self.lineOffset <= sem.token.lineOffset && sem.token.literal.endIndex <= self.literal.endIndex
                  }),
                  !newChildren.isEmpty {
            var copy = self
            copy.children = newChildren.map { $0.token }
            return copy.highlighted(semanticTokens: semanticTokens)
        }
        
        var str = ""
        var i = lineOffset
        for child in children {
            if i < child.lineOffset {
                str += literal[i..<child.lineOffset]
            }
            str += child.highlighted(semanticTokens: semanticTokens)
            i = child.literal.endIndex
        }
        if i < literal.endIndex {
            str += literal[i..<literal.endIndex]
        }
        return highlighted(content: str, type: tokenType, modifiers: [])
    }
    
    private func highlighted(content: String, type: TokenType, modifiers: SemanticToken.Modifiers) -> String {
        var content = content
        if type == .keyword && modifiers.contains(.documentation) {
            return content.bold
        }
        if let color = type.color {
            content = content[keyPath: color]
        }
        if modifiers.contains(.deprecated) {
            content = content.applyingStyle(.strikethrough)
        }
        return content
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
        var msg = "file:\(token.lineNumber + 1):\(token.lineOffset.utf16Offset(in: base)): \(severity.colorfulDescription): \(message)\n"
        msg += base.replacingOccurrences(of: "\t", with: " ") + "\n"
        msg += String(repeating: " ", count: base.distance(from: base.startIndex, to: token.lineOffset))
        msg += "^" + String(repeating: "~", count: max(0, token.literal.count - 1))
        if let hint = hint {
            msg += "\nhint: \(hint)"
        }
        return msg
    }
}
