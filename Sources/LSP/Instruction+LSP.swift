//
//  Instruction+LSP.swift
//  GRPH LSP
// 
//  Created by Emil Pedersen on 25/09/2021.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LanguageServerProtocol
import GRPHLexer
import GRPHGenerator
import LSPLogging

extension Array where Element == Instruction {
    func outline(lexedLines: [Token], semanticTokens: [SemanticToken]) -> [DocumentSymbol] {
        var result: [DocumentSymbol] = []
        for inst in self {
            switch inst {
            case let fn as FunctionDeclarationBlock:
                guard let token = semanticTokens.first(where: { $0.token.lineNumber == fn.lineNumber && $0.token.tokenType == .function && $0.modifiers.contains(.declaration) }) else {
                    log("oh no, found no semantic token matching \(fn)", level: .error)
                    break
                }
                let lastLine = fn.children.last ?? fn
                let lastLineDesc = lexedLines.first(where: { $0.lineNumber == lastLine.lineNumber })?.description ?? ""
                result.append(DocumentSymbol(
                    name: fn.generated.name,
                    detail: fn.generated.signature,
                    kind: .function,
                    deprecated: token.modifiers.contains(.deprecated),
                    range: Position(line: fn.lineNumber, utf16index: 0)..<Position(line: lastLine.lineNumber, utf16index: lastLineDesc.endIndex.utf16Offset(in: lastLineDesc)),
                    selectionRange: token.token.positionRange,
                    children: fn.children.outline(lexedLines: lexedLines, semanticTokens: semanticTokens)
                ))
            case let decl as VariableDeclarationInstruction:
                guard let token = semanticTokens.first(where: { $0.token.lineNumber == decl.lineNumber && $0.token.tokenType == .variable && $0.modifiers.contains(.declaration) }) else {
                    log("oh no, found no semantic token matching \(decl)", level: .error)
                    break
                }
                let line = lexedLines.first(where: { $0.lineNumber == decl.lineNumber })?.description ?? ""
                result.append(DocumentSymbol(
                    name: decl.name,
                    detail: "\(decl.constant ? "final " : "")\(decl.type) \(decl.name)",
                    kind: .variable,
                    deprecated: token.modifiers.contains(.deprecated),
                    range: Position(line: decl.lineNumber, utf16index: 0)..<Position(line: decl.lineNumber, utf16index: line.endIndex.utf16Offset(in: line)),
                    selectionRange: token.token.positionRange,
                    children: []
                ))
            case let block as BlockInstruction:
                result.append(contentsOf: block.children.outline(lexedLines: lexedLines, semanticTokens: semanticTokens))
            default:
                break
            }
        }
        return result
    }
}
