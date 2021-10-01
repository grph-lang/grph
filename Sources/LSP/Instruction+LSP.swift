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
    /// Generates an outline for the file: A symbol tree containing declared variables and functions
    /// - Parameters:
    ///   - lexedLines: An array of all lines, as fully lexed tokens. Used to calculate end of lines
    ///   - semanticTokens: A list of semantic tokens from the generator. Used to find the position of the declaring token
    /// - Returns: A tree of LSP document symbols, used to draw the outline & the breadcrumb client-side
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
    
    /// Collects the lines that are part of the scope at `line`. Used by autocomplete to know what variables are in scope. The inout parameters must be empty when called, and will contain the result upon returning
    /// - Parameters:
    ///   - line: the line at which to search for scope
    ///   - outsideFunction: the lines at which declared variables must be final to be available in the current scope
    ///   - local: the lines at which declared variable are always available
    func collectScope(line: Int, outsideFunction: inout [Int], local: inout [Int]) {
        for inst in self {
            if inst.lineNumber > line {
                return
            }
            switch inst {
            case let fn as FunctionDeclarationBlock:
                let lastLine = fn.children.last ?? fn
                if (fn.lineNumber...lastLine.lineNumber).contains(line) {
                    outsideFunction += local
                    local = []
                    local.append(inst.lineNumber)
                    fn.children.collectScope(line: line, outsideFunction: &outsideFunction, local: &local)
                    return
                }
            case let block as BlockInstruction:
                let lastLine = block.children.last ?? block
                if (block.lineNumber...lastLine.lineNumber).contains(line) {
                    local.append(inst.lineNumber)
                    block.children.collectScope(line: line, outsideFunction: &outsideFunction, local: &local)
                    return
                }
            default:
                local.append(inst.lineNumber)
            }
        }
    }
}
