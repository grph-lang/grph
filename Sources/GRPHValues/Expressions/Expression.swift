//
//  Expression.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation

public protocol Expression: CustomStringConvertible {
    
    func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType
    
    var string: String { get }
    
    var needsBrackets: Bool { get }
}

public extension Expression {
    var bracketized: String {
        needsBrackets ? "[\(string)]" : string
    }
    
    var description: String {
        string
    }
}