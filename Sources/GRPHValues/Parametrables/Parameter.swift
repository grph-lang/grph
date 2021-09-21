//
//  Parameter.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 05/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct Parameter {
    
    static let shapeName = Parameter(name: "name", type: SimpleType.string, optional: true)
    static let pos = Parameter(name: "location", type: SimpleType.pos)
    static let pos1 = Parameter(name: "pos1", type: SimpleType.pos)
    static let pos2 = Parameter(name: "pos2", type: SimpleType.pos)
    static let zpos = Parameter(name: "zpos", type: SimpleType.integer, optional: true)
    static let size = Parameter(name: "size", type: SimpleType.pos)
    static let rotation = Parameter(name: "rotation", type: SimpleType.rotation, optional: true)
    static let paint = Parameter(name: "paint", type: SimpleType.paint)
    static let strokeWidth = Parameter(name: "strokeWidth", type: SimpleType.float, optional: true)
    static let strokeType = Parameter(name: "strokeType", type: SimpleType.stroke, optional: true)
    static let strokeDashArray = Parameter(name: "strokeDashArray", type: ArrayType(content: SimpleType.float), optional: true)

    public let name: String
    public let type: GRPHType
    public let optional: Bool
    
    public init(name: String, type: GRPHType, optional: Bool = false) {
        self.name = name
        self.type = type
        self.optional = optional
    }
    
    public var string: String {
        "\(type.string) \(name)\(optional ? "?" : "")"
    }
}
