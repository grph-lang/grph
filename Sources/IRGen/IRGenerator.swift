//
//  IRGenerator.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 26/01/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM
import cllvm

public class IRGenerator {
    let builder: IRBuilder
    
    let debug: DIBuilder
    let debugCU: CompileUnitMetadata
    let debugFile: FileMetadata
    
    public var module: Module { builder.module }
    
    var globalContext: VariableOwningIRContext?
    
    var currentContext: IRContext?
    
    public init(filename: String, debugInfo: Bool) {
        builder = IRBuilder(module: Module(name: filename))
        debug = DIBuilder(module: builder.module)
        let url = URL(fileURLWithPath: filename).absoluteURL
        debugFile = debug.buildFile(named: filename, in: url.deletingLastPathComponent().path)
        debugCU = debug.buildCompileUnit(for: .c, in: debugFile, kind: debugInfo ? .full : .none)
    }
    
    public func build(from instructions: [GRPHValues.Instruction]) throws {
        globalContext = VariableOwningIRContext(parent: nil)
        globalContext!.scope = debugFile
        let topLevelContext = VariableOwningIRContext(parent: globalContext)
        currentContext = topLevelContext
        
        topLevelContext.scope = debug.buildFunction(named: "main", linkageName: "main", scope: debugFile, file: debugFile, line: 1, scopeLine: 1, type: debug.buildSubroutineType(in: debugFile, parameterTypes: [], returnType: debug.buildBasicType(named: "llvmtype<i32>", encoding: .signed, flags: [], size: Size(bits: 32))), flags: [])
        let main = builder.addFunction("main", type: FunctionType([], IntType.int32))
        main.addMetadata(topLevelContext.currentScope, kind: .dbg)
        builder.positionAtEnd(of: main.appendBasicBlock(named: "entry"))
        
        try instructions.buildAll(generator: self)
        
        builder.buildRet(IntType.int32.constant(0))
        debug.module.addFlag(named: "Dwarf Version", constant: IntType.int32.constant(2), behavior: .warning)
        debug.module.addFlag(named: "Debug Info Version", constant: IntType.int32.constant(Module.debugMetadataVersion), behavior: .warning)
        debug.finalize()
        globalContext = nil
        currentContext = nil
    }
}
