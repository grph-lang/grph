//
//  ASTNode.swift
//  GRPH Values
// 
//  Created by Emil Pedersen on 01/02/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

/// A reflective protocol to look at an hierarchy of instructions and expressions (the AST)
public protocol ASTNode {
    /// A type, such as TryBlock or BinaryExpression
    var astNodeType: String { get }
    /// Additional information about a node (type of operation, function name, etc)
    var astNodeData: String { get }
    /// The nodes inside of the current one
    var astChildren: [ASTElement] { get }
}

public extension ASTNode {
    var astNodeType: String {
        String(describing: type(of: self))
    }
}

public struct ASTElement {
    public var name: String
    public var value: [ASTNode]
}
