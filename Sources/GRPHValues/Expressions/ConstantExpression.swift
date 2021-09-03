//
//  ConstantExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

struct ConstantExpression: Expression {
    let value: StatefulValue
    
    init(boolean: Bool) {
        self.value = boolean
    }
    
    init(stroke: Stroke) {
        self.value = stroke
    }
    
    init(direction: Direction) {
        self.value = direction
    }
    
    init(pos: Pos) {
        self.value = pos
    }
    
    init(int: Int) {
        self.value = int
    }
    
    init(float: Float) {
        self.value = float
    }
    
    init(rot: Rotation) {
        self.value = rot
    }
    
    func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        value.type // The value is always known at compile time, so this is fine
    }
    
    var string: String { value.state }
    
    var needsBrackets: Bool { false }
}
