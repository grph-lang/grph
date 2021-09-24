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
            hoverProvider: true//,
            ))))
//            completionProvider: CompletionOptions(resolveProvider: false, triggerCharacters: ["."]),
////            signatureHelpProvider: nil, // provide parameter completion
//            definitionProvider: true, // jump to definition
//            implementationProvider: .bool(true), // jump to symbol implementation
//            referencesProvider: true, // view all references to symbol
//            documentHighlightProvider: true, // view all references to symbol, for highlighting
//            documentSymbolProvider: true, // list all symbols
//            workspaceSymbolProvider: false, // same, in workspace
//            codeActionProvider: .bool(false), // actions, such as refactors or quickfixes
//            colorProvider: .bool(false), // could work, by parsing `color()` calls which only use int literals, and return values
//            foldingRangeProvider: .bool(true),
//            semanticTokensProvider: SemanticTokensOptions(
//                legend: SemanticTokensLegend(
//                    tokenTypes: LSPSemanticTokenType.allCases.map(\.rawValue),
//                    tokenModifiers: SemanticToken.Modifiers.legend),
//                range: .bool(true),
//                full: .value(.init(delta: false)))))))
    }
    
    // MARK: - Text sync
    
    func didOpenDocument(_ notif: DidOpenTextDocumentNotification) {
        documents[notif.textDocument.uri] = Document(item: notif.textDocument)
    }
    
    func didChangeDocument(_ notif: DidChangeTextDocumentNotification) {
        documents[notif.textDocument.uri]?.handle(notif)
    }
    
    func didCloseDocument(_ notif: DidCloseTextDocumentNotification) {
        documents[notif.textDocument.uri] = nil
    }
    
    func hover(_ request: Request<HoverRequest>) {
        guard let doc = documents[request.params.textDocument.uri] else {
            request.reply(.failure(.unknown("document not open")))
            return
        }
        
        doc.ensureTokenized()
        
        guard let tokenized = doc.tokenized,
              let doc = tokenized.documentatation else {
            request.reply(.failure(.unknown("tokenization error")))
                  return
        }
        
        guard let token = doc.semanticTokens.last(where: { $0.token.positionRange.contains(request.params.position) }),
              let documentation = doc.findDocumentation(token: token) else {
            request.reply(.success(nil))
            return
        }
        
        request.reply(.success(HoverResponse(contents: HoverResponseContents.markupContent(MarkupContent(kind: .markdown, value: documentation.markdown)), range: token.token.positionRange)))
    }
}
