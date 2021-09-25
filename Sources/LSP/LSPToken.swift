//
//  LSPToken.swift
//  GRPH LSP
// 
//  Created by Emil Pedersen on 25/09/2021.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHGenerator

struct LSPToken {
    var lineNumber: Int
    var literal: Substring
    var type: LSPSemanticTokenType
    var modifiers: SemanticToken.Modifiers
    
    func generateData(line: inout Int, character: inout Int) -> [UInt32] {
        let deltaLine: UInt32
        let deltaChar: UInt32
        if lineNumber != line {
            deltaLine = UInt32(lineNumber - line)
            line = lineNumber
            character = literal.startIndex.utf16Offset(in: literal.base)
            deltaChar = UInt32(character)
        } else {
            deltaLine = 0
            let char = literal.startIndex.utf16Offset(in: literal.base)
            deltaChar = UInt32(char - character)
            character = char
        }
        let len = UInt32(literal.endIndex.utf16Offset(in: literal.base) - character)
        return [deltaLine, deltaChar, len, type.index, modifiers.rawValue]
    }
}
