//
//  TopLevelCompilingContext.swift
//  Graphism
//
//  Created by Emil Pedersen on 26/08/2021.
//

import Foundation

/// This is the only context that doesn't have a parent
class TopLevelCompilingContext: VariableOwningCompilingContext {
    
    init(compiler: GRPHCompilerProtocol) {
        super.init(compiler: compiler, parent: nil)
        variables.append(contentsOf: Self.defaultVariables)
    }
    
    override func assertParentNonNil() {
        
    }
    
    override func addVariable(_ variable: Variable, global: Bool) {
        variables.append(variable)
    }
}

extension TopLevelCompilingContext {
    static var defaultVariables: [Variable] {
        [
            Variable(name: "this", type: SimpleType.rootThisType, content: "currentDocument", final: true),
            Variable(name: "back", type: SimpleType.Background, final: false, compileTime: true),
            Variable(name: "WHITE", type: SimpleType.color,
                     content: ColorPaint.components(red: 1, green: 1, blue: 1),
                     final: true),
            Variable(name: "BLACK", type: SimpleType.color,
                     content: ColorPaint.components(red: 0, green: 0, blue: 0),
                     final: true),
            Variable(name: "RED", type: SimpleType.color,
                     content: ColorPaint.components(red: 1, green: 0, blue: 0),
                     final: true),
            Variable(name: "GREEN", type: SimpleType.color,
                     content: ColorPaint.components(red: 0, green: 1, blue: 0),
                     final: true),
            Variable(name: "BLUE", type: SimpleType.color,
                     content: ColorPaint.components(red: 0, green: 0, blue: 1),
                     final: true),
            Variable(name: "ORANGE", type: SimpleType.color,
                     content: ColorPaint.components(red: 1, green: 0.78, blue: 0),
                     final: true),
            Variable(name: "YELLOW", type: SimpleType.color,
                     content: ColorPaint.components(red: 1, green: 1, blue: 0),
                     final: true),
            Variable(name: "PINK", type: SimpleType.color,
                     content: ColorPaint.components(red: 1, green: 0.69, blue: 0.69),
                     final: true),
            Variable(name: "PURPLE", type: SimpleType.color,
                     content: ColorPaint.components(red: 1, green: 0, blue: 1),
                     final: true),
            Variable(name: "AQUA", type: SimpleType.color,
                     content: ColorPaint.components(red: 0, green: 1, blue: 1),
                     final: true),
            Variable(name: "ALPHA", type: SimpleType.color,
                     content: ColorPaint.components(red: 0, green: 0, blue: 0, alpha: 0),
                     final: true),
        ]
    }
}
