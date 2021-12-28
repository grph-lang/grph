//
//  main.swift
//  Graphism CLI
//
//  Created by Emil Pedersen on 06/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import ArgumentParser
import Foundation
import GRPHValues

struct GraphismCLI: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "grph",
            abstract: "Run operations on GRPH code",
            version: RequiresInstruction.currentVersion(plugin: "GRPH")!.description,
            subcommands: [RunCommand.self, HighlightCommand.self, CompileCommand.self, LegacyCommand.self],
            defaultSubcommand: LegacyCommand.self
        )
    }
}

GraphismCLI.main()
