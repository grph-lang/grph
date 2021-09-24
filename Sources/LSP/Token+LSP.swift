//
//  Token+LSP.swift
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
import GRPHLexer
import GRPHGenerator
import LanguageServerProtocol

enum LSPSemanticTokenType: String, CaseIterable {
    /// A simple or documentation comment
    case comment
    
    /// A variable name
    case variable
    /// A function name
    case function
    /// A method name
    case method
    /// A label name
    case label // extension to the standard LSP tokens
    /// A type
    case type
    /// A direction or a stroke type
    case enumMember
    /// A #-command name
    case command // extension to the standard LSP tokens
    /// A namespace
    case namespace
    /// A parameter name in a function definition
    case parameter
    /// A property of a type
    case property
    
    /// A keyword (as(?)(!), is, global, static, final, auto), or a bool/null literal
    case keyword
    /// An integer, a float, a rotation, or a position
    case number
    /// A double-quoted string or single-quoted file
    case string
    
    /// Any operator
    case `operator`
}

extension TokenType {
    // convert & stuff
}

extension Token {
    
    var startPosition: Position {
        Position(line: lineNumber, utf16index: literal.startIndex.utf16Offset(in: literal.base))
    }
    
    var endPosition: Position {
        Position(line: lineNumber, utf16index: literal.endIndex.utf16Offset(in: literal.base))
    }
    
    var positionRange: Range<Position> {
        startPosition..<endPosition
    }
}

extension SemanticToken.Modifiers {
    static let legend = [
        "declaration",
        "definition",
        "readonly",
        "deprecated",
        "modification",
        "documentation",
        "defaultLibrary",
    ]
}
