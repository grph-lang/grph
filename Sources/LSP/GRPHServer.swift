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
//            signatureHelpProvider: nil, // provide parameter completion (no)
            definitionProvider: true, // jump to definition
            implementationProvider: .bool(true), // jump to symbol implementation
            referencesProvider: true, // view all references to symbol
//            documentHighlightProvider: true, // view all references to symbol, for highlighting
//            documentSymbolProvider: true, // list all symbols
//            workspaceSymbolProvider: false, // same, in workspace
//            codeActionProvider: .bool(false), // actions, such as refactors or quickfixes
//            colorProvider: .bool(false), // could work, by parsing `color()` calls which only use int literals, and return values
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
        
        request.reply(.success(doc.findReferences(of: symbol).map({ Location(uri: request.params.textDocument.uri, range: $0.token.positionRange) })))
    }
}
