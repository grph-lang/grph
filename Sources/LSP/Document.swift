//
//  Document.swift
//  GRPH LSP
// 
//  Created by Emil Pedersen on 24/09/2021.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import LanguageServerProtocol
import LSPLogging
import GRPHLexer
import GRPHGenerator
import GRPHValues
import DocGen

/// Represents a GRPH file
class Document {
    var item: TextDocumentItem
    var tokenized: TokenizedDocument?
    
    init(item: TextDocumentItem) {
        self.item = item
    }
    
    func handle(_ notif: DidChangeTextDocumentNotification) {
        if let version = notif.textDocument.version {
            item.version = version
        }
        for change in notif.contentChanges {
            if change.range != nil {
                log("Text change range shouldn't be specified as we only accept full files", level: .error)
            }
            item.text = change.text
        }
        tokenized = nil
    }
    
    func ensureTokenized(publisher: GRPHServer) {
        if tokenized == nil {
            tokenized = TokenizedDocument(text: item.text)
            publisher.publishDiagnostics(tokenized!.diagnostics, for: self)
        }
    }
}

/// A processed (lexed, generated and documented) GRPH script
struct TokenizedDocument {
    
    var lexed: [Token]
    var diagnostics: [Notice]
    var documentation: DocGenerator?
    var instructions: [Instruction]
    var imports: [Importable]
    
    var successful: Bool
    
    init(text: String) {
        log("Tokenizing", level: .debug)
        let lexer = GRPHLexer()
        lexed = lexer.parseDocument(content: text)
        diagnostics = lexer.diagnostics
        successful = !diagnostics.contains(where: { $0.severity == .error })
        if successful {
            let gen = GRPHGenerator(lines: lexed)
            gen.resolvedSemanticTokens = []
            successful = gen.compile()
            instructions = gen.rootBlock.children
            imports = gen.imports
            diagnostics.append(contentsOf: gen.diagnostics)
            
            var doc = DocGenerator(lines: lexed, semanticTokens: gen.resolvedSemanticTokens!)
            doc.generateSemanticTokensForDefaults = true
            doc.generate()
            diagnostics.append(contentsOf: doc.diagnostics)
            self.documentation = doc
        } else {
            instructions = []
            imports = []
        }
    }
}
