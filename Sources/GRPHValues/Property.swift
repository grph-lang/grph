//
//  Property.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 03/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public protocol Property {
    var name: String { get }
    var type: GRPHType { get }
}

public struct TypeConstant: Property {
    public let name: String
    public let type: GRPHType
    public let value: GRPHValue
}

public protocol Field: Property {
    func getValue(on: GRPHValue) -> GRPHValue
    func setValue(on: inout GRPHValue, value: GRPHValue) throws
    
    var writeable: Bool { get }
}

public struct VirtualField<On: GRPHValue>: Field {
    public let name: String
    public let type: GRPHType
    
    let getter: (_ on: On) -> GRPHValue
    let setter: ((_ on: inout On, _ newValue: GRPHValue) throws -> Void)?
    
    public init(name: String, type: GRPHType, getter: @escaping (On) -> GRPHValue, setter: ((inout On, GRPHValue) throws -> Void)? = nil) {
        self.name = name
        self.type = type
        self.getter = getter
        self.setter = setter
    }
    
    public func getValue(on: GRPHValue) -> GRPHValue {
        getter(on as! On)
    }
    
    public func setValue(on: inout GRPHValue, value: GRPHValue) throws {
        guard let setter = setter else {
            // ADD throw
            fatalError("TODO")
        }
        if var copy = on as? On {
            try setter(&copy, value)
            on = copy
        } else {
            fatalError("Type check failed \(on) is not a \(On.self) aka \(type.string)")
        }
    }
    
    public var writeable: Bool { setter != nil }
}

public struct ErasedField: Field {
    public let name: String
    public let type: GRPHType
    
    let getter: (_ on: GRPHValue) -> GRPHValue
    let setter: ((_ on: inout GRPHValue, _ newValue: GRPHValue) throws -> Void)?
    
    public func getValue(on: GRPHValue) -> GRPHValue {
        getter(on)
    }
    
    public func setValue(on: inout GRPHValue, value: GRPHValue) throws {
        guard let setter = setter else {
            // ADD throw
            fatalError("TODO")
        }
        try setter(&on, value)
    }
    
    public var writeable: Bool { setter != nil }
}

public struct KeyPathField<On: GRPHValue, Value: GRPHValue>: Field {
    public let name: String
    public let type: GRPHType
    
    let keyPath: WritableKeyPath<On, Value>
    
    public func getValue(on: GRPHValue) -> GRPHValue {
        if let on = on as? On {
            return on[keyPath: keyPath]
        } else {
            fatalError("Type check failed \(on) is not a \(On.self) aka \(type.string)")
        }
    }
    
    public func setValue(on: inout GRPHValue, value: GRPHValue) {
        if var copy = on as? On {
            copy[keyPath: keyPath] = value as! Value
            on = copy
        } else {
            fatalError("Type check failed \(on) is not a \(On.self) aka \(type.string)")
        }
    }
    
    public var writeable: Bool { true }
}
