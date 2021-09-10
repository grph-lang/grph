//
//  File.swift
//  File
//
//  Created by Emil Pedersen on 10/09/2021.
//

import Foundation
import GRPHGenerator
import GRPHValues

public struct Documentation {
    // modifier will always include declaration
    public var symbol: SemanticToken
    
    public var info: String
    public var since: String?
    
    public var seeAlso: [String]
    public var paramDoc: [Parameter]
    
    public struct Parameter {
        public var name: String
        public var doc: String?
    }
}
