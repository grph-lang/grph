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

public class IRGenerator {
    let builder: IRBuilder
    
    public var module: Module { builder.module }
    
    var globalContext: VariableOwningIRContext?
    
    var currentContext: IRContext?
    
    public var mangleNames: Bool = true
    internal var buildingAThunk: Bool = false
    
    public init(filename: String) {
        builder = IRBuilder(module: Module(name: filename))
    }
    
    public func build(from instructions: [GRPHValues.Instruction]) throws {
        globalContext = VariableOwningIRContext(parent: nil)
        
        var argv = builder.addGlobal("grphv_global_argv", type: PointerType.toVoid)
        argv.linkage = .external
        
        globalContext!.insert(variable: Variable(name: "argv", ref: .global(argv)))
        let topLevelContext = VariableOwningIRContext(parent: globalContext)
        currentContext = topLevelContext
        
        let main = builder.addFunction("grph_entrypoint", type: FunctionType([], VoidType()))
        let allocas = main.appendBasicBlock(named: "entry.allocas")
        let entry = main.appendBasicBlock(named: "entry")
        
        builder.positionAtEnd(of: allocas)
        builder.buildBr(entry)
        
        builder.positionAtEnd(of: entry)
        
        try instructions.buildAll(generator: self)
        
        builder.buildRetVoid()
        globalContext = nil
        currentContext = nil
    }
}
