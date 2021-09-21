//
//  JFont.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 18/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct JFont: StatefulValue, Equatable {
    static public let plain = 0
    static public let bold = 1
    static public let italic = 2
    
    public var type: GRPHType { SimpleType.font }
    
    public var name: String?
    public var size: Int
    public var weight: Int = JFont.plain
    
    public init(name: String? = nil, size: Int, weight: Int = JFont.plain) {
        self.name = name
        self.size = size
        self.weight = weight
    }
    
    public var bold: Bool { (weight & JFont.bold) == JFont.bold }
    public var italic: Bool { (weight & JFont.italic) == JFont.italic }
    
    public var grphName: String {
        get {
            name ?? "San Francisco"
        }
        set {
            name = newValue
        }
    }
    
    public var state: String {
        "font(\(name?.asLiteral ?? "")\(size) \(weight))"
    }
}
