//
//  GRPHType.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

struct OptionalType: GRPHType {
    let wrapped: GRPHType
    
    var string: String {
        if wrapped is MultiOrType {
            return "<\(wrapped.string)>?"
        }
        return "\(wrapped.string)?"
    }
    
    func isInstance(of other: GRPHType) -> Bool {
        return other is OptionalType && wrapped.isInstance(of: (other as! OptionalType).wrapped)
    }
    
    var constructor: Constructor? {
        Constructor(parameters: [Parameter(name: "wrapped", type: wrapped, optional: true)], type: self, storage: .generic(signature: "T?(T wrapped?)"))
    }
}

struct MultiOrType: GRPHType {
    let type1, type2: GRPHType
    
    var string: String {
        "\(type1.string)|\(type2.string)"
    }
    
    func isInstance(of other: GRPHType) -> Bool {
        if let option = other as? OptionalType {
            return isInstance(of: option.wrapped)
        }
        return other.isTheMixed || (type1.isInstance(of: other) && type2.isInstance(of: other))
    }
}

struct ArrayType: GRPHType {
    let content: GRPHType
    
    var string: String {
        "{\(content.string)}"
    }
    
    var supertype: GRPHType {
        if content.isTheMixed {
            return SimpleType.mixed
        }
        return ArrayType(content: content.supertype)
    }
    
    func isInstance(of other: GRPHType) -> Bool {
        if let option = other as? OptionalType {
            return isInstance(of: option.wrapped)
        }
        if let array = other as? ArrayType {
            return content.isInstance(of: array.content)
        }
        return other.isTheMixed
    }
    
    var fields: [Field] {
        return [VirtualField<GRPHArray>(name: "length", type: SimpleType.integer, getter: { $0.count })]
    }
    
    var constructor: Constructor? {
        Constructor(parameters: [Parameter(name: "element", type: content, optional: true)], type: self, varargs: true, storage: .generic(signature: "{T}(T wrapped...)"))
    }
    
    var includedMethods: [Method] {
        [
            Method(ns: RandomNameSpace(), name: "shuffled", inType: self, parameters: [], returnType: self, storage: .generic(signature: "{T} {T}.random>shuffled[]")),
            Method(ns: StandardNameSpace(), name: "copy", inType: self, parameters: [], returnType: self, storage: .generic(signature: "{T} {T}.copy[]"))
        ]
    }
}

struct FuncRefType: GRPHType {
    let returnType: GRPHType
    let parameterTypes: [GRPHType]
    
    var string: String {
        "funcref<\(returnType.string)><\(parameterTypes.map{ $0.string }.joined(separator: "+"))>"
    }
    
    var supertype: GRPHType {
        if returnType.isTheMixed {
            return SimpleType.funcref
        }
        return FuncRefType(returnType: returnType.supertype, parameterTypes: parameterTypes)
    }
    
    func isInstance(of other: GRPHType) -> Bool {
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
    
    var fields: [Field] {
        return [VirtualField<FuncRef>(name: "_funcName", type: SimpleType.string, getter: { $0.funcName })]
    }
    
    var constructor: Constructor? {
        Constructor(parameters: [Parameter(name: "constant", type: returnType, optional: returnType.isTheVoid)], type: self, storage: .generic(signature: "funcref<T><>(T wrapped)"))
    }
}

extension FuncRefType: Parametrable {
    var parameters: [Parameter] {
        parameterTypes.enumerated().map { index, type in
            Parameter(name: "$\(index)", type: type)
        }
    }
    
    var varargs: Bool { false }
}
