//
//  GRPHValue.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 30/06/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

/* Immutable types should be structs, mutable types should be classes */
public protocol GRPHValue {
    var type: GRPHType { get }
    func isEqual(to other: GRPHValue) -> Bool
}

public protocol StatefulValue: GRPHValue {
    var state: String { get }
}

public protocol GRPHNumber: GRPHValue {
    init(grph: GRPHNumber)
}

public extension GRPHValue where Self: Equatable {
    /// Note that this default implementation doesn't work with multi-inheritence (subclasses) !!!
    func isEqual(to other: GRPHValue) -> Bool {
        if let value = other as? Self {
            return value == self
        }
        return false
    }
}

extension Int: StatefulValue, GRPHNumber {
    
    public init?(byCasting value: GRPHValue) {
        if let num = value as? Float {
            self.init(num)
        } else if let rot = value as? Rotation {
            self.init(rot.value)
        } else if let str = value as? String {
            self.init(decoding: str) // May return nil
        } else if let b = value as? Bool {
            self = b ? 1 : 0
        } else {
            return nil
        }
    }
    
    public init?<S: StringProtocol>(decoding string: S) {
        if string.hasPrefix("0x") || string.hasPrefix("0X") {
            self.init(string.dropFirst(2), radix: 16)
        } else if string.hasPrefix("0o") {
            self.init(string.dropFirst(2), radix: 8)
        } else if string.hasPrefix("0b") {
            self.init(string.dropFirst(2), radix: 2)
        } else if string.hasPrefix("#") {
            self.init(string.dropFirst(), radix: 16)
        } else if string.hasPrefix("0z") {
            self.init(string.dropFirst(2), radix: 36)
        } else if string.hasPrefix("-") {
            self.init(decoding: string.dropFirst())
            self = -self
        } else if string.hasPrefix("+") {
            self.init(decoding: string.dropFirst())
        } else {
            self.init(string)
        }
    }
    
    public init(grph: GRPHNumber) {
        if let int = grph as? Int {
            self.init(int)
        } else if let num = grph as? Float {
            self.init(num)
        } else {
            fatalError()
        }
    }
    
    public var type: GRPHType { SimpleType.integer }
    public var state: String { String(self) }
}

extension String: StatefulValue {
    
    public init?(byCasting value: GRPHValue) {
        if let str = value as? String {
            self.init(str) // Not a literal
        } else if let val = value as? StatefulValue {
            self.init(val.state)
        } else if let val = value as? CustomStringConvertible {
            self.init(val.description)
        } else {
            return nil
        }
    }
    
    public var type: GRPHType { SimpleType.string }
    
    public var state: String {
        debugDescription
    }
    
    var asLiteral: String {
        self.state + " "
    }
}

extension Float: StatefulValue, GRPHNumber {
    
    public init?(byCasting value: GRPHValue) {
        if let int = value as? Int {
            self.init(int)
        } else if let rot = value as? Rotation {
            self.init(rot.value)
        } else if let str = value as? String {
            self.init(str) // May return nil
        } else {
            return nil
        }
    }
    
    public init(grph: GRPHNumber) {
        if let int = grph as? Int {
            self.init(int)
        } else if let num = grph as? Float {
            self.init(num)
        } else {
            fatalError()
        }
    }
    
    public var type: GRPHType { SimpleType.float }
    public var state: String { "\(self)F" }
}

extension Bool: StatefulValue {
    
    public init?(byCasting value: GRPHValue) {
        if let int = value as? Int {
            self.init(int != 0)
        } else if let num = value as? Float {
            self.init(num != 0)
        } else if let rot = value as? Rotation {
            self.init(rot.value != 0)
        } else if let str = value as? String {
            self.init(!str.isEmpty)
        } else if let pos = value as? Pos {
            self.init(pos.x != 0 || pos.y != 0)
        } else if let arr = value as? GRPHArray {
            self.init(arr.count != 0)
        } else if let opt = value as? GRPHOptional { // never really reached
            self.init(!opt.isEmpty)
        } else {
            self.init(true)
        }
    }
    
    public var type: GRPHType { SimpleType.boolean }
    public var state: String { self ? "true" : "false" }
}

public extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safeExact index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

public extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript<T>(safe index: Index) -> T? where Element == Optional<T> {
        return indices.contains(index) ? self[index] : nil
    }
}

public enum GRPHVoid: StatefulValue {
    case void
    
    public var type: GRPHType {
        SimpleType.void
    }
    
    public var state: String {
        "void.VOID"
    }
    
    public func isEqual(to other: GRPHValue) -> Bool {
        other is GRPHVoid
    }
}
