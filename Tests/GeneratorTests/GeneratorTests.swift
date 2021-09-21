//
//  GeneratorTests.swift
//  GRPH Tests
//
//  Created by Emil Pedersen on 01/09/2021.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import XCTest
@testable import GRPHGenerator
import GRPHLexer
import GRPHValues

final class GeneratorTests: XCTestCase {
    var lexer = GRPHLexer()
    var generator = GRPHGenerator(lines: [])
    var lineNumber = 0
    
    override func setUp() {
        lexer = GRPHLexer()
        generator = GRPHGenerator(lines: [])
        generator.context = TopLevelCompilingContext(compiler: generator)
        lineNumber = 0
    }
    
    func testLexing() throws {
        generator.context.addVariable(Variable(name: "pos1", type: SimpleType.pos, final: true), global: false)
        generator.context.addVariable(Variable(name: "maybeInt", type: SimpleType.integer.optional, final: true), global: false)
        generator.imports.append(NameSpaces.namespace(named: "random")!)
        
        parsing(expression: #"funcref<string><string+string>("static")"#)
        parsing(expression: #"pos1 + pos(1 2)"#)
        parsing(expression: "1 + 2 as int", expected: "[1 + 2] as integer")
        parsing(expression: "-maybeInt!")
        parsing(expression: "[{1 , 2 , 3} as {int}].shuffled[]", expected: "[<integer>{1, 2, 3} as {integer}].random>shuffled[]")
        parsing(expression: "[{integer}(1 2 3)].random>shuffled[]", expected: "{integer}(1 2 3).random>shuffled[]")
    }
    
    func parsing(expression: String, expected: String? = nil) {
        do {
            var tokens = lexer.parseLine(lineNumber: lineNumber, content: expression)
            lexer.tokenDetectLine(line: &tokens)
            
            let trimmed = generator.trimUselessStuff(children: tokens.children)
            
            let exp = try generator.resolveExpression(tokens: trimmed, infer: nil)
            
            XCTAssertEqual(exp.string, expected ?? expression)
            lineNumber += 1
        } catch let err as DiagnosticCompileError {
            print(err.notice.represent())
            XCTFail(err.notice.represent())
        } catch let err {
            XCTFail("\(err)")
        }
    }
}

