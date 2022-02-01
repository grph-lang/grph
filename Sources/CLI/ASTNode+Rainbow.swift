//
//  ASTNode+Rainbow.swift
//  Graphism CLI
//
//  Created by Emil Pedersen on 09/09/2021.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import Rainbow
import GRPHValues

extension ASTNode {
    func dumpAST(indent: String = "") -> String {
        let nextIndent = indent + "  "
        return "\(indent)- \(astNodeType.magenta): \(astNodeData.green)\n" + astChildren.map { element -> String in
            let elem: String
            if element.value.isEmpty {
                elem = "(empty)\n"
            } else {
                elem = "\n" + element.value.map {
                    $0.dumpAST(indent: nextIndent + "  ")
                }.joined()
            }
            return "\(nextIndent)- \(element.name.red): \(elem)"
        }.joined()
    }
}
