//
//  GRPHType.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

public struct OptionalType: GRPHType {
    public let wrapped: GRPHType
    
    public var string: String {
        if wrapped is MultiOrType {
            return "<\(wrapped.string)>?"
        }
        return "\(wrapped.string)?"
    }
    
    public func isInstance(of other: GRPHType) -> Bool {
        return other is OptionalType && wrapped.isInstance(of: (other as! OptionalType).wrapped)
    }
    
    public var constructor: Constructor? {
        Constructor(parameters: [Parameter(name: "wrapped", type: wrapped, optional: true)], type: self, storage: .generic(signature: "T?(T wrapped?)"))
    }
}

public struct MultiOrType: GRPHType {
    public let type1, type2: GRPHType
    
    public var string: String {
        "\(type1.string)|\(type2.string)"
    }
    
    public func isInstance(of other: GRPHType) -> Bool {
        if let option = other as? OptionalType {
            return isInstance(of: option.wrapped)
        }
        return other.isTheMixed || (type1.isInstance(of: other) && type2.isInstance(of: other))
    }
}

public struct ArrayType: GRPHType {
    public let content: GRPHType
    
    public var string: String {
        "{\(content.string)}"
    }
    
    public var supertype: GRPHType {
        if content.isTheMixed {
            return SimpleType.mixed
        }
        return ArrayType(content: content.supertype)
    }
    
    public func isInstance(of other: GRPHType) -> Bool {
        if let option = other as? OptionalType {
            return isInstance(of: option.wrapped)
        }
        if let array = other as? ArrayType {
            return content.isInstance(of: array.content)
        }
        return other.isTheMixed
    }
    
    public var fields: [Field] {
        return [VirtualField<GRPHArray>(name: "length", type: SimpleType.integer, getter: { $0.count })]
    }
    
    public var constructor: Constructor? {
        Constructor(parameters: [Parameter(name: "element", type: content, optional: true)], type: self, varargs: true, storage: .generic(signature: "{T}(T wrapped...)"))
    }
    
    public var includedMethods: [Method] {
        [
            Method(ns: RandomNameSpace(), name: "shuffled", inType: self, parameters: [], returnType: self, storage: .generic(signature: "{T} {T}.random>shuffled[]")),
            Method(ns: StandardNameSpace(), name: "copy", inType: self, parameters: [], returnType: self, storage: .generic(signature: "{T} {T}.copy[]"))
        ]
    }
}

public struct FuncRefType: GRPHType {
    public let returnType: GRPHType
    public let parameterTypes: [GRPHType]
    
    public var string: String {
        "funcref<\(returnType.string)><\(parameterTypes.map{ $0.string }.joined(separator: "+"))>"
    }
    
    public var supertype: GRPHType {
        if returnType.isTheMixed {
            return SimpleType.funcref
        }
        return FuncRefType(returnType: returnType.supertype, parameterTypes: parameterTypes)
    }
    
    public func isInstance(of other: GRPHType) -> Bool {
        if let option = other as? OptionalType {
            return isInstance(of: option.wrapped)
        }
        if let other = other as? FuncRefType,
           self.parameterTypes.count == other.parameterTypes.count {
            // (funcref<num><integer+num>(5) is funcref<mixed><integer+integer>) == true
            return self.returnType.isInstance(of: other.returnType)
        }
        if let simple = other as? SimpleType {
            if simple == .funcref || simple == .mixed {
                return true
            }
        }
        return false
    }
    
    public var fields: [Field] {
        return [VirtualField<FuncRef>(name: "_funcName", type: SimpleType.string, getter: { $0.funcName })]
    }
    
    public var constructor: Constructor? {
        Constructor(parameters: [Parameter(name: "constant", type: returnType, optional: returnType.isTheVoid)], type: self, storage: .generic(signature: "funcref<T><>(T wrapped)"))
    }
}

extension FuncRefType: Parametrable {
    public var parameters: [Parameter] {
        parameterTypes.enumerated().map { index, type in
            Parameter(name: "$\(index)", type: type)
        }
    }
    
    public var varargs: Bool { false }
}
