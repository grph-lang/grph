//
//  MultiOrType.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 15/02/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

extension MultiOrType: RepresentableGRPHType {
    
    var onlyReferenceTypes: Bool {
        guard let type1 = type1 as? RepresentableGRPHType,
              let type2 = type2 as? RepresentableGRPHType else {
            return false
        }
        return type1.representationMode == .referenceType && type2.representationMode == .referenceType
    }
    
    var genericsVector: [RepresentableGRPHType] {
        var result: [RepresentableGRPHType] = []
        if let nested = type1 as? MultiOrType {
            result.append(contentsOf: nested.genericsVector)
        } else {
            result.append(type1 as! RepresentableGRPHType)
        }
        if let nested = type2 as? MultiOrType {
            result.append(contentsOf: nested.genericsVector)
        } else {
            result.append(type2 as! RepresentableGRPHType)
        }
        var uniquified: [RepresentableGRPHType] = []
        var uniquifier: Set<String> = []
        for type in result {
            if uniquifier.insert(type.string).inserted {
                uniquified.append(type)
            }
        }
        return uniquified
    }
    
    var typeid: UInt8 {
        onlyReferenceTypes ? 253 : 254
    }
    
    var representationMode: RepresentationMode {
        onlyReferenceTypes ? .referenceType : .existential
    }
    
    func asLLVM() -> IRType {
        onlyReferenceTypes ? PointerType(pointee: IntType.int8) : GRPHTypes.existential
    }
}
