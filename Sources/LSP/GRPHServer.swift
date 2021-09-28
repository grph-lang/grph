//
//  GRPHServer.swift
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
import LanguageServerProtocolJSONRPC
import LSPLogging
import GRPHLexer
import GRPHGenerator

class GRPHServer: MessageHandler {
    
    let client: JSONRPCConnection
    let queue: DispatchQueue = DispatchQueue(label: "language-server-queue", qos: .userInitiated)
    
    var root: DocumentURI!
    var documents: [DocumentURI: Document] = [:]
    
    init(client: JSONRPCConnection) {
        self.client = client
    }
    
    func handle<Notification>(_ notif: Notification, from: ObjectIdentifier) where Notification : NotificationType {
        log("received: \(notif)", level: .debug)
        queue.async { [unowned self] in
            switch notif {
            case is ExitNotification:
                client.close()
            case let notif as DidOpenTextDocumentNotification:
                didOpenDocument(notif)
            case let notif as DidChangeTextDocumentNotification:
                didChangeDocument(notif)
            case let notif as DidCloseTextDocumentNotification:
                didCloseDocument(notif)
            case is DidSaveTextDocumentNotification, is InitializedNotification:
                break // ignore
            default:
                log("unknown notif \(notif)", level: .warning)
            }
        }
    }
    
    func handle<R>(_ params: R, id: RequestID, from clientID: ObjectIdentifier, reply: @escaping (LSPResult<R.Response>) -> Void) where R : RequestType {
        log("received: \(params)", level: .debug)
        queue.async { [unowned self] in
            let cancellationToken = CancellationToken()

            let request = Request(params, id: id, clientID: clientID, cancellation: cancellationToken, reply: reply)

            switch request {
            case let request as Request<InitializeRequest>:
                initialize(request)
            case let request as Request<ShutdownRequest>:
                request.reply(VoidResponse()) // ignore
            case let request as Request<HoverRequest>:
                hover(request)
            case let request as Request<DocumentSemanticTokensRequest>:
                semanticTokens(request)
            case let request as Request<DefinitionRequest>:
                jumpToDefinition(request, position: request.params.position)
            case let request as Request<ImplementationRequest>:
                jumpToDefinition(request, position: request.params.position)
            case let request as Request<ReferencesRequest>:
                findReferences(request)
            case let request as Request<DocumentHighlightRequest>:
                highlightReferences(request)
            case let request as Request<DocumentSymbolRequest>:
                outline(request)
            case let request as Request<DocumentColorRequest>:
                findStaticColors(request)
            case let request as Request<ColorPresentationRequest>:
                presentColor(request)
            default:
                log("unknown request \(request)")
            }
        }
    }
    
    func initialize(_ request: Request<InitializeRequest>) {
        root = request.params.rootURI ?? request.params.rootPath.map { DocumentURI(URL(fileURLWithPath: $0)) }
        request.reply(.success(InitializeResult(capabilities: ServerCapabilities(
            textDocumentSync: TextDocumentSyncOptions(
                openClose: true,
                change: .full,
                willSave: false),
            hoverProvider: true,
//            completionProvider: CompletionOptions(resolveProvider: false, triggerCharacters: ["."]),
            signatureHelpProvider: nil, // provide parameter completion (no)
            definitionProvider: true, // jump to definition
            implementationProvider: .bool(true), // jump to symbol implementation
            referencesProvider: true, // view all references to symbol
            documentHighlightProvider: true, // view all references to symbol, for highlighting
            documentSymbolProvider: true, // list all symbols
            workspaceSymbolProvider: false, // same, in workspace
            codeActionProvider: .bool(false), // actions, such as refactors or quickfixes
            colorProvider: .bool(true), // parses `color()` constructors which only use number literals
//            foldingRangeProvider: .bool(true),
            semanticTokensProvider: SemanticTokensOptions(
                legend: SemanticTokensLegend(
                    tokenTypes: LSPSemanticTokenType.allCases.map(\.name),
                    tokenModifiers: SemanticToken.Modifiers.legend),
                range: .bool(false),
                full: .value(.init(delta: false)))))))
    }
    
    // MARK: - Text sync
    
    func didOpenDocument(_ notif: DidOpenTextDocumentNotification) {
        let doc = Document(item: notif.textDocument)
        documents[notif.textDocument.uri] = doc
        doc.ensureTokenized(publisher: self)
    }
    
    func didChangeDocument(_ notif: DidChangeTextDocumentNotification) {
        guard let doc = documents[notif.textDocument.uri] else {
            log("change text in closed document", level: .error)
            return
        }
        doc.handle(notif)
        queue.asyncAfter(deadline: .now() + 1) { [weak doc] in
            doc?.ensureTokenized(publisher: self)
        }
    }
    
    func didCloseDocument(_ notif: DidCloseTextDocumentNotification) {
        documents[notif.textDocument.uri] = nil
    }
    
    // MARK: Diagnostics
    
    func publishDiagnostics(_ diag: [Notice], for doc: Document) {
        client.send(PublishDiagnosticsNotification(uri: doc.item.uri, version: doc.item.version, diagnostics: diag.map { $0.toLSP(doc: doc.item.uri) }))
    }
    
    // MARK: - Requests
    
    func ensureDocTokenized<T>(request: Request<T>) -> TokenizedDocument? where T: TextDocumentRequest {
        guard let doc = documents[request.params.textDocument.uri] else {
            request.reply(.failure(.unknown("document not open")))
            return nil
        }
        
        doc.ensureTokenized(publisher: self)
        
        guard let tokenized = doc.tokenized else {
            request.reply(.failure(.unknown("tokenization error")))
            return nil
        }
        return tokenized
    }
    
    func hover(_ request: Request<HoverRequest>) {
        guard let tokenized = ensureDocTokenized(request: request) else {
            return
        }
        
        guard let doc = tokenized.documentatation else {
            request.reply(.failure(.unknown("tokenization error")))
                  return
        }
        
        guard let token = doc.semanticTokens.last(where: { $0.token.positionRangeClosed.contains(request.params.position) }),
              let documentation = doc.findDocumentation(token: token) else {
            request.reply(.success(nil))
            return
        }
        
        request.reply(.success(HoverResponse(contents: HoverResponseContents.markupContent(MarkupContent(kind: .markdown, value: documentation.markdown)), range: token.token.positionRange)))
    }
    
    func semanticTokens(_ request: Request<DocumentSemanticTokensRequest>) {
        guard let tokenized = ensureDocTokenized(request: request) else {
            return
        }
        
        let semtokens = tokenized.documentatation?.semanticTokens ?? []
        let lspTokens = tokenized.lexed.flatMap({ token in
            token.flattenedComplete(semanticTokens: semtokens.filter({ $0.token.lineNumber == token.lineNumber }))
        })
        
        var line: Int = 0
        var character: Int = 0
        var collect: [UInt32] = []
        collect.reserveCapacity(lspTokens.count * 5)
        for lspToken in lspTokens {
            collect.append(contentsOf: lspToken.generateData(line: &line, character: &character))
        }
        
        request.reply(.success(DocumentSemanticTokensResponse(resultId: nil, data: collect)))
    }
    
    func jumpToDefinition<T>(_ request: Request<T>, position: Position) where T: TextDocumentRequest, T.Response == LocationsOrLocationLinksResponse? {
        guard let tokenized = ensureDocTokenized(request: request) else {
            return
        }
        
        guard let symbol = tokenized.documentatation?.semanticTokens.first(where: { $0.token.positionRangeClosed.contains(position) }),
              let decl = tokenized.documentatation?.findDeclaration(for: symbol) else {
            request.reply(.success(nil))
            return
        }
        
        request.reply(.success(.locations([Location(uri: request.params.textDocument.uri, range: decl.token.positionRange)])))
    }
    
    func findReferences(_ request: Request<ReferencesRequest>) {
        guard let tokenized = ensureDocTokenized(request: request) else {
            return
        }
        
        guard let doc = tokenized.documentatation,
              let symbol = doc.semanticTokens.first(where: { $0.token.positionRangeClosed.contains(request.params.position) }) else {
            request.reply(.success([]))
            return
        }
        
        request.reply(.success(doc.findReferences(of: symbol).map({
            Location(uri: request.params.textDocument.uri, range: $0.token.positionRange)
        })))
    }
    
    func highlightReferences(_ request: Request<DocumentHighlightRequest>) {
        guard let tokenized = ensureDocTokenized(request: request) else {
            return
        }
        
        guard let doc = tokenized.documentatation,
              let symbol = doc.semanticTokens.first(where: { $0.token.positionRangeClosed.contains(request.params.position) }) else {
            request.reply(.success([]))
            return
        }
        
        request.reply(.success(doc.findReferences(of: symbol).map({
            DocumentHighlight(range: $0.token.positionRange, kind: $0.modifiers.contains(.modification) ? .write : .read)
        })))
    }
    
    /// Used for outline and breadcrumbs: Return an outline, as a tree
    /// Our AST doesn't use indentation to make trees
    /// Our I&E, however, can be used to populate this
    func outline(_ request: Request<DocumentSymbolRequest>) {
        guard let tokenized = ensureDocTokenized(request: request) else {
            return
        }
        
        request.reply(.success(.documentSymbols(tokenized.instructions.outline(lexedLines: tokenized.lexed, semanticTokens: tokenized.documentatation?.semanticTokens ?? []))))
    }
    
    func findStaticColors(_ request: Request<DocumentColorRequest>) {
        guard let tokenized = ensureDocTokenized(request: request) else {
            return
        }
        
        var result: [ColorInformation] = []
        for sem in tokenized.documentatation?.semanticTokens ?? [] {
            if case .constructor(let c) = sem.data,
               c.name == "color",
               let line = tokenized.lexed.first(where: { $0.lineNumber == sem.token.lineNumber }) {
                var index = sem.token.literal.endIndex
                if let paren = searchParentheses(at: &index, in: line) {
                    let content = paren.children.stripped
                    if content.count == 3 || content.count == 4,
                       content.allSatisfy({ $0.tokenType == .numberLiteral }),
                       case .integer(let r) = content[0].data,
                       case .integer(let g) = content[1].data,
                       case .integer(let b) = content[2].data {
                        let range = Token(lineNumber: line.lineNumber, lineOffset: sem.token.lineOffset, literal: sem.token.literal.base[sem.token.lineOffset..<paren.literal.endIndex], tokenType: .squareBrackets).positionRange
                        if content.count == 4 {
                            if case .float(let a) = content[3].data {
                                // rgba
                                result.append(ColorInformation(range: range, color: Color(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, alpha: Double(a))))
                            } // else invalid
                        } else {
                            // rgb
                            result.append(ColorInformation(range: range, color: Color(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, alpha: 1)))
                        }
                    }
                }
            }
        }
        
        request.reply(.success(result))
    }
    
     // recursively search the parentheses in the AST
    func searchParentheses(at index: inout String.Index, in token: Token) -> Token? {
        if index == token.lineOffset {
            if token.tokenType == .parentheses {
                return token
            } else if token.tokenType == .whitespace, !token.literal.isEmpty {
                // continue search after ignoreable whitespace
                index = token.literal.endIndex
                return nil // we never have children anyway
            }
        }
        for child in token.children {
            if let success = searchParentheses(at: &index, in: child) {
                return success
            }
        }
        return nil
    }
    
    func presentColor(_ request: Request<ColorPresentationRequest>) {
        let color = request.params.color
        let r = Int(color.red * 255)
        let g = Int(color.green * 255)
        let b = Int(color.blue * 255)
        var result: [ColorPresentation] = []
        if color.alpha >= 1 {
            result.append(ColorPresentation(label: "color(\(r) \(g) \(b))", textEdit: nil, additionalTextEdits: nil))
        }
        result.append(ColorPresentation(label: "color(\(r) \(g) \(b) \(color.alpha))", textEdit: nil, additionalTextEdits: nil))
        request.reply(.success(result))
    }
}
