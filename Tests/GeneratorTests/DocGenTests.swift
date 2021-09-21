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
    func testCompleteness() throws {
        print(DocGenerator.builtins.diagnostics.map({ $0.represent() }).joined(separator: "\n"))
        print(DocGenerator.builtins.diagnostics.count, "diagnostics in builtin.grph")
        for diag in DocGenerator.builtins.diagnostics {
            record(XCTIssue(type: .assertionFailure, compactDescription: diag.message, sourceCodeContext: XCTSourceCodeContext(location: XCTSourceCodeLocation(filePath: String(DocGenerator._builtinsSourcePath), lineNumber: diag.token.lineNumber + 1))))
        }
        print(DocGenerator.builtins.documentation)
        for f in NameSpaces.instances.flatMap({ $0.exportedFunctions }) {
            let doc = DocGenerator.builtins.findDocumentation(symbol: SemanticToken(token: Token(lineNumber: 0, lineOffset: f.name.startIndex, literal: f.name[...], tokenType: .function), modifiers: .none, data: .function(f)))
            print(doc)
            XCTAssertNotNil(doc, "missing function \(f.signature)")
        }
    }
}

