//
//  TopLevelCompilingContext.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 26/08/2021.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

/// This is the only context that doesn't have a parent
public class TopLevelCompilingContext: VariableOwningCompilingContext {
    
    public init(compiler: GRPHCompilerProtocol) {
        super.init(compiler: compiler, parent: nil)
        variables.append(contentsOf: Self.defaultVariables)
    }
    
    public override func assertParentNonNil() {
        
    }
    
    public override func addVariable(_ variable: Variable, global: Bool) {
        variables.append(variable)
    }
}

public extension TopLevelCompilingContext {
    static var defaultVariables: [Variable] {
        [
            Variable(name: "this", type: SimpleType.rootThisType, content: "currentDocument", final: true, builtin: true),
            Variable(name: "back", type: SimpleType.Background, final: false, builtin: true, compileTime: true),
            Variable(name: "WHITE", type: SimpleType.color,
                     content: ColorPaint.components(red: 1, green: 1, blue: 1),
                     final: true, builtin: true),
            Variable(name: "BLACK", type: SimpleType.color,
                     content: ColorPaint.components(red: 0, green: 0, blue: 0),
                     final: true, builtin: true),
            Variable(name: "RED", type: SimpleType.color,
                     content: ColorPaint.components(red: 1, green: 0, blue: 0),
                     final: true, builtin: true),
            Variable(name: "GREEN", type: SimpleType.color,
                     content: ColorPaint.components(red: 0, green: 1, blue: 0),
                     final: true, builtin: true),
            Variable(name: "BLUE", type: SimpleType.color,
                     content: ColorPaint.components(red: 0, green: 0, blue: 1),
                     final: true, builtin: true),
            Variable(name: "ORANGE", type: SimpleType.color,
                     content: ColorPaint.components(red: 1, green: 0.78, blue: 0),
                     final: true, builtin: true),
            Variable(name: "YELLOW", type: SimpleType.color,
                     content: ColorPaint.components(red: 1, green: 1, blue: 0),
                     final: true, builtin: true),
            Variable(name: "PINK", type: SimpleType.color,
                     content: ColorPaint.components(red: 1, green: 0.69, blue: 0.69),
                     final: true, builtin: true),
            Variable(name: "PURPLE", type: SimpleType.color,
                     content: ColorPaint.components(red: 1, green: 0, blue: 1),
                     final: true, builtin: true),
            Variable(name: "AQUA", type: SimpleType.color,
                     content: ColorPaint.components(red: 0, green: 1, blue: 1),
                     final: true, builtin: true),
            Variable(name: "ALPHA", type: SimpleType.color,
                     content: ColorPaint.components(red: 0, green: 0, blue: 0, alpha: 0),
                     final: true, builtin: true),
        ]
    }
}
