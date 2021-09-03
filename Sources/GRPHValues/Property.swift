//
//  Property.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation

protocol Property {
    var name: String { get }
    var type: GRPHType { get }
}

struct TypeConstant: Property {
    let name: String
    let type: GRPHType
    let value: GRPHValue
}

protocol Field: Property {
    func getValue(on: GRPHValue) -> GRPHValue
    func setValue(on: inout GRPHValue, value: GRPHValue) throws
    
    var writeable: Bool { get }
}

struct VirtualField<On: GRPHValue>: Field {
    let name: String
    let type: GRPHType
    
    let getter: (_ on: On) -> GRPHValue
    let setter: ((_ on: inout On, _ newValue: GRPHValue) throws -> Void)?
    
    init(name: String, type: GRPHType, getter: @escaping (On) -> GRPHValue, setter: ((inout On, GRPHValue) throws -> Void)? = nil) {
        self.name = name
        self.type = type
        self.getter = getter
        self.setter = setter
    }
    
    func getValue(on: GRPHValue) -> GRPHValue {
        getter(on as! On)
    }
    
    func setValue(on: inout GRPHValue, value: GRPHValue) throws {
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
    
    var writeable: Bool { setter != nil }
}

struct ErasedField: Field {
    let name: String
    let type: GRPHType
    
    let getter: (_ on: GRPHValue) -> GRPHValue
    let setter: ((_ on: inout GRPHValue, _ newValue: GRPHValue) throws -> Void)?
    
    func getValue(on: GRPHValue) -> GRPHValue {
        getter(on)
    }
    
    func setValue(on: inout GRPHValue, value: GRPHValue) throws {
        guard let setter = setter else {
            // ADD throw
            fatalError("TODO")
        }
        try setter(&on, value)
    }
    
    var writeable: Bool { setter != nil }
}

struct KeyPathField<On: GRPHValue, Value: GRPHValue>: Field {
    let name: String
    let type: GRPHType
    
    let keyPath: WritableKeyPath<On, Value>
    
    func getValue(on: GRPHValue) -> GRPHValue {
        if let on = on as? On {
            return on[keyPath: keyPath]
        } else {
            fatalError("Type check failed \(on) is not a \(On.self) aka \(type.string)")
        }
    }
    
    func setValue(on: inout GRPHValue, value: GRPHValue) {
        if var copy = on as? On {
            copy[keyPath: keyPath] = value as! Value
            on = copy
        } else {
            fatalError("Type check failed \(on) is not a \(On.self) aka \(type.string)")
        }
    }
    
    var writeable: Bool { true }
}
