//
//  DocGenTests.swift
//  GRPH Tests
//
//  Created by Emil Pedersen on 01/09/2021.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import XCTest
@testable import DocGen
import GRPHLexer
import GRPHGenerator
import GRPHValues

final class DocGenTests: XCTestCase {
    func testDiagnostics() throws {
        print(DocGenerator.builtins.diagnostics.map({ $0.represent() }).joined(separator: "\n"))
        print(DocGenerator.builtins.diagnostics.count, "diagnostics in builtin.grph")
        for diag in DocGenerator.builtins.diagnostics {
            record(XCTIssue(type: .assertionFailure, compactDescription: diag.message, sourceCodeContext: XCTSourceCodeContext(location: XCTSourceCodeLocation(filePath: String(DocGenerator._builtinsSourcePath), lineNumber: diag.token.lineNumber + 1))))
        }
    }
    
    func testSeeAlsoExists() throws {
        for doc in DocGenerator.builtins.documentation.values {
            print(doc.symbol.documentationNames)
            for see in doc.seeAlso {
                XCTAssertNotNil(DocGenerator.builtins.findDocumentation(sloppyName: see), "\(see) not found in doc for \(doc.symbol.token.literal)")
            }
        }
    }
    
    func testFunctionCompleteness() throws {
        for f in NameSpaces.instances.flatMap({ $0.exportedFunctions }) {
            let doc = DocGenerator.builtins.findLocalDocumentation(symbol: SemanticToken(token: Token(lineNumber: 0, lineOffset: f.name.startIndex, literal: f.name[...], tokenType: .function), modifiers: .none, data: .function(f)))
            XCTAssertNotNil(doc, "missing function \(f.signature)")
        }
    }
    
    func testMethodCompleteness() throws {
        // this doesn't include methods defined directly in types!
        for f in NameSpaces.instances.flatMap({ $0.exportedMethods }) {
            let doc = DocGenerator.builtins.findLocalDocumentation(symbol: SemanticToken(token: Token(lineNumber: 0, lineOffset: f.name.startIndex, literal: f.name[...], tokenType: .method), modifiers: .none, data: .method(f)))
            XCTAssertNotNil(doc, "missing method \(f.signature)")
        }
    }
}

