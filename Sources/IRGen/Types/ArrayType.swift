//
//  ArrayType.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 26/02/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM
import GRPHLexer
import GRPHGenerator
import cllvm

extension GRPHValues.ArrayType: RepresentableGRPHType {
    var typeid: UInt8 {
        129
    }
    
    var genericsVector: [RepresentableGRPHType] {
        [content as! RepresentableGRPHType]
    }
    
    var representationMode: RepresentationMode {
        .referenceType
    }
    
    var vwt: ValueWitnessTable {
        ValueWitnessTable(copy: ValueWitnessTable.ref.copy, destroy: "grphvwt_release_array")
    }
    
    func asLLVM() throws -> IRType {
        PointerType.toVoid
    }
    
    func upcast(generator: IRGenerator, to: RepresentableGRPHType, value: Expression) throws -> (IRValue, ownedCopy: Bool) {
        if to.isTheMixed || to == self {
            return try upcastDefault(generator: generator, to: to, value: value)
        }
        guard let to = to as? Self else {
            throw GRPHCompileError(type: .typeMismatch, message: "Can't upcast \(self) to \(to)")
        }
        let fn = try to.generateConversionThunk(generator: generator)
        return try value.borrow(generator: generator, expect: SimpleType.mixed) { val in
            let result = generator.builder.buildCall(fn, args: [SimpleType.mixed.paramCCWrap(generator: generator, value: val)])
            // can't fail, it is an upcast
            return (generator.builder.buildExtractValue(result, index: 1), ownedCopy: true)
        }
    }
    
    func generateConversionThunk(generator: IRGenerator) throws -> LLVM.Function {
        let lexer = GRPHLexer()
        let thunkName = "__thunk_tmp\(UInt(bitPattern: self.string.hashValue))"
        let lines = lexer.parseDocument(content: """
        #compiler indent spaces
        #typealias elemty \(self.content.string)
        boolean mixed_is_array[mixed value] = #external

        #function {elemty}? \(thunkName)[mixed input]
            #if !mixed_is_array[input]
                #return null
            #unchecked[downcast] // it is not actually an {mixed}, but we can pretend
                {mixed} val = input as! {mixed}
            {elemty} result = ()
            int i = 0
            int len = val.length
            #while i < len
                mixed out = val{i} // can't work normally while pretending, special cased
                result{+} = out as elemty
                i += 1
            #return result
        """)
        let compiler = GRPHGenerator(lines: lines)
        guard compiler.compile() else {
            for diag in lexer.diagnostics + compiler.diagnostics {
                print(diag.represent())
            }
            throw GRPHCompileError(type: .unsupported, message: "could not compile array conversion thunk")
        }
        
        // call to grpharr_get -> grpharr_get_mixed
        let mangleNames = generator.mangleNames
        let buildingAThunk = generator.buildingAThunk
        generator.mangleNames = false
        generator.buildingAThunk = true
        defer {
            generator.buildingAThunk = buildingAThunk
            generator.mangleNames = mangleNames
        }
        try compiler.rootBlock.children.buildAll(generator: generator)
        
        var thunk = generator.builder.module.function(named: thunkName)!
        thunk.name = "Thunk for converting array to \(self)"
        thunk.linkage = .internal
        return thunk
    }
}
