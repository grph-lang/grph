//
//  main.swift
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
import ArgumentParser
import LanguageServerProtocol
import LanguageServerProtocolJSONRPC
import LSPLogging

extension LogLevel: ExpressibleByArgument { }

struct LSPMain: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Language Server Protocol implementation for GRPH"
    )
    
    /// Whether to wait for a response before handling the next request.
    /// Used for testing.
    @Flag(name: .customLong("sync"))
    var syncRequests = false
    
    @Option(help: "Set the logging level [debug|info|warning|error] (default: \(LogLevel.default))")
    var logLevel: LogLevel?
    
    @Option(
        help: "Whether to enable server-side filtering in code-completion"
    )
    var completionServerSideFiltering = true
    
    @Option(
        help: "When server-side filtering is enabled, the maximum number of results to return"
    )
    var completionMaxResults = 200
    
    func run() throws {
        if let logLevel = logLevel {
            Logger.shared.currentLevel = logLevel
        } else {
            Logger.shared.setLogLevel(environmentVariable: "SOURCEKIT_LOGGING")
        }
        
        // Dup stdout and redirect the fd to stderr so that a careless print()
        // will not break our connection stream.
        let realStdout = dup(STDOUT_FILENO)
        if realStdout == -1 {
            fatalError("failed to dup stdout: \(strerror(errno)!)")
        }
        if dup2(STDERR_FILENO, STDOUT_FILENO) == -1 {
            fatalError("failed to redirect stdout -> stderr: \(strerror(errno)!)")
        }
        
        let realStdoutHandle = FileHandle(fileDescriptor: realStdout, closeOnDealloc: false)
        
        let clientConnection = JSONRPCConnection(
            protocol: MessageRegistry.lspProtocol,
            inFD: FileHandle.standardInput,
            outFD: realStdoutHandle,
            syncRequests: syncRequests
        )
        
        let server = GRPHServer(client: clientConnection)
        clientConnection.start(receiveHandler: server, closeHandler: {
            withExtendedLifetime(realStdoutHandle) {}
            _Exit(0)
        })
        
        dispatchMain()
    }
}

LSPMain.main()
