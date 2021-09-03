//
//  ConstantExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

public struct ConstantExpression: Expression {
    public let value: StatefulValue
    
    public init(boolean: Bool) {
        self.value = boolean
    }
    
    public init(stroke: Stroke) {
        self.value = stroke
    }
    
    public init(direction: Direction) {
        self.value = direction
    }
    
    public init(pos: Pos) {
        self.value = pos
    }
    
    public init(int: Int) {
        self.value = int
    }
    
    public init(float: Float) {
        self.value = float
    }
    
    public init(rot: Rotation) {
        self.value = rot
    }
    
    public func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        value.type // The value is always known at compile time, so this is fine
    }
    
    public var string: String { value.state }
    
    public var needsBrackets: Bool { false }
}
