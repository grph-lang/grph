//
//  ReplCommand.swift
//  Graphism CLI
//
//  Created by Emil Pedersen on 28/01/2022.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import ArgumentParser
import Foundation
import GRPHLexer
import GRPHGenerator
import GRPHRuntime
import GRPHValues
import DocGen

struct ReplCommand: ParsableCommand {
    
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "repl", abstract: "Open the REPL prompt")
    }
    
    func run() throws {
        let compiler = GRPHGenerator(lines: [])
        let runtime = GRPHRuntime(instructions: compiler.instructions, image: GImage(delegate: {}), argv: ["repl"])
        
        runtime.runAsREPL {
            interactive(compiler: compiler, runtime: runtime)
        }
    }
    
    func interactive(compiler: GRPHGenerator, runtime: GRPHRuntime) {
        defer {
            print()
        }
        while true {
            print(">>> ", terminator: "")
            guard let line = readLine() else {
                return
            }
            do {
                guard let context = runtime.context else {
                    print("Error: No context")
                    break
                }
                let lexer = GRPHLexer()
                var tokens = lexer.parseLine(lineNumber: -1, content: line)
                lexer.tokenDetectLine(line: &tokens)
                compiler.context = DebuggingCompilingContext(adapting: context, compiler: compiler)
                let e = try compiler.resolveExpression(tokens: compiler.trimUselessStuff(children: tokens.children), infer: nil)
                print("Result = \(try e.evalIfRunnable(context: context))")
            } catch let e as GRPHCompileError {
                print("Error: \(e.message)")
            } catch let e as DiagnosticCompileError {
                print("Error: \(e.notice.message)")
            } catch let e as GRPHRuntimeError {
                print("Error: \(e.message)")
            } catch {
                print("Error: Unexpected error")
            }
        }
    }
}
