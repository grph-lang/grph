//
//  FunctionDeclarationBlock.swift
//  GRPH Generator
//
//  Created by Emil Pedersen on 06/09/2021.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHLexer
import GRPHValues

extension FunctionDeclarationBlock {
    /// - Note: Tokens must be stripped
    convenience init(lineNumber: Int, compiler: GRPHGenerator, tokens: [Token]) throws {
        self.init(lineNumber: lineNumber)
        let context = createContext(&compiler.context)
        
        guard !tokens.isEmpty else {
            throw GRPHCompileError(type: .parse, message: "'#function' requires 'returnType funcName[...]' syntax, it can't be empty")
        }
        
        // syntax:
        // returnType funcName[]
        // returnType funcName[] = defaultValueExpr
        guard let paramsIndex = tokens.firstIndex(where: { $0.tokenType == .squareBrackets }),
              paramsIndex >= 2 else {
            throw DiagnosticCompileError(notice: Notice(token: Token(compound: tokens, type: .squareBrackets), severity: .error, source: .generator, message: "Could not parse function declaration, expected syntax 'returnType funcName[...]'"))
        }
        
        let name = tokens[paramsIndex - 1]
        defer { // make sure generated is set (or use .none if we fail parsing)
            context.generator.resolveSemanticToken(name.withType(.function).withModifiers([.declaration, isExternal ? [] : .definition], data: generated.map { .function($0) }))
        }
        guard name.tokenType == .identifier && name.literal.allSatisfy({ $0.isLetter || $0 == "_" }) else {
            throw DiagnosticCompileError(notice: Notice(token: name, severity: .error, source: .generator, message: "Expected function name to only contain letters and underscores"))
        }
        
        let typeLit = Token(compound: Array(tokens[...(paramsIndex - 2)]), type: .type)
        let returnTypeOrAuto: GRPHType?
        if typeLit.literal == "auto" {
            returnTypeOrAuto = nil
        } else if let type = GRPHTypes.parse(context: context, literal: String(typeLit.literal)) {
            returnTypeOrAuto = type
        } else {
            throw DiagnosticCompileError(notice: Notice(token: typeLit, severity: .error, source: .generator, message: "Could not find type '\(typeLit.literal)'"))
        }
        context.generator.resolveSemanticToken(typeLit.withModifiers([]))
        
        let params = tokens[paramsIndex].children.stripped.split(on: .comma)
        var varargs = false
        defaults = .init(repeating: nil, count: params.count)
        var pars: [Parameter] = []
        pars.reserveCapacity(params.count)
        for (i, param) in params.enumerated() {
            let par = try parseParam(param: param, i: i, context: context, varargs: &varargs, isLast: i == params.count - 1)
            
            pars.append(par)
        }
        
        let returnType: GRPHType
        let storage: Function.Storage
        if tokens.count == paramsIndex + 1 {
            if let returnTypeOrAuto = returnTypeOrAuto {
                returnType = returnTypeOrAuto
            } else {
                throw DiagnosticCompileError(notice: Notice(token: typeLit, severity: .error, source: .generator, message: "Cannot infer auto type without a default return value", hint: "Insert ` = defaultValue` at the end of the line to add a default return value"))
            }
            storage = .block(self)
        } else {
            guard tokens[paramsIndex + 1].tokenType == .assignmentOperator else {
                throw DiagnosticCompileError(notice: Notice(token: tokens[paramsIndex + 1], severity: .error, source: .generator, message: "Expected a `=` after the function signature to define the default return value"))
            }
            guard tokens.count > paramsIndex + 2 else {
                throw DiagnosticCompileError(notice: Notice(token: tokens[paramsIndex + 1], severity: .error, source: .generator, message: "The default return value cannot be empty", hint: "Remove the `=` sign to not use any default return value"))
            }
            let drvTokens = Array(tokens[(paramsIndex + 2)...])
            if let firstTok = drvTokens.first,
               firstTok.tokenType == .commandName,
               firstTok.literal == "#external" {
                // external declaration!
                if let returnTypeOrAuto = returnTypeOrAuto {
                    returnType = returnTypeOrAuto
                } else {
                    throw DiagnosticCompileError(notice: Notice(token: typeLit, severity: .error, source: .generator, message: "Cannot infer auto type without a default return value in external declaration"))
                }
                storage = .external
            } else {
                let drv = try context.generator.resolveExpression(tokens: drvTokens, infer: returnTypeOrAuto)
                returnDefault = drv
                returnType = returnTypeOrAuto ?? drv.getType()
                storage = .block(self)
                if !returnType.isInstance(context: context, expression: drv) {
                    throw GRPHCompileError(type: .parse, message: "Expected a default return value of type \(returnType), found a \(drv.getType())")
                }
            }
        }
        
        generated = Function(ns: NameSpaces.none, name: String(name.literal), parameters: pars, returnType: returnType, varargs: varargs, storage: storage)
        context.imports.append(generated)
    }
    
    func parseParam(param: [Token], i: Int, context: BlockCompilingContext, varargs: inout Bool, isLast: Bool) throws -> Parameter {
        let equal = param.firstIndex(where: { $0.tokenType == .assignmentOperator }) ?? param.endIndex
        guard equal >= 2 else {
            throw DiagnosticCompileError(notice: Notice(token: Token(compound: param, type: .squareBrackets), severity: .error, source: .generator, message: "Expected parameter to have a type and name"))
        }
        
        let last = param[equal - 1]
        let optional: Bool
        let name: Token
        if last.tokenType == .varargs {
            guard isLast else {
                throw DiagnosticCompileError(notice: Notice(token: last, severity: .error, source: .generator, message: "The varargs '...' must be the last parameter"))
            }
            guard equal == param.endIndex else {
                throw DiagnosticCompileError(notice: Notice(token: param[equal], severity: .error, source: .generator, message: "A parameter can't be both varargs and have a default value"))
            }
            varargs = true
            optional = false // require at least 1 argument for some reason
            name = param[equal - 2]
        } else if last.literal == "?" {
            guard equal == param.endIndex else {
                throw DiagnosticCompileError(notice: Notice(token: last, severity: .error, source: .generator, message: "Do not specify '?' when having a default parameter value"))
            }
            optional = true
            name = param[equal - 2]
        } else {
            optional = equal != param.endIndex
            name = last
        }
        
        guard name.tokenType == .identifier else {
            throw DiagnosticCompileError(notice: Notice(token: name, severity: .error, source: .generator, message: "Unexpected token: expected a variable name"))
        }
        
        let typeLit = Token(compound: Array(param[...(equal - 2)]), type: .type)
        let ptypeOrAuto: GRPHType?
        if typeLit.literal == "auto" {
            ptypeOrAuto = nil
        } else if let type = GRPHTypes.parse(context: context, literal: String(typeLit.literal)) {
            ptypeOrAuto = type
        } else {
            throw DiagnosticCompileError(notice: Notice(token: typeLit, severity: .error, source: .generator, message: "Could not find type '\(typeLit.literal)'"))
        }
        context.generator.resolveSemanticToken(typeLit.withModifiers([]))
        
        let ptype: GRPHType
        if equal < param.endIndex - 1 {
            let exp = try context.generator.resolveExpression(tokens: Array(param[(equal + 1)...]), infer: ptypeOrAuto)
            defaults[i] = exp
            ptype = ptypeOrAuto ?? exp.getType()
        } else if equal == param.endIndex {
            guard let ptypeOrAuto = ptypeOrAuto else {
                throw DiagnosticCompileError(notice: Notice(token: typeLit, severity: .error, source: .generator, message: "Cannot infer parameter type without a default parameter value"))
            }
            ptype = ptypeOrAuto
        } else {
            throw DiagnosticCompileError(notice: Notice(token: param[equal], severity: .error, source: .generator, message: "Expected default parameter value after the equal sign"))
        }
        let par = Parameter(name: name.description, type: ptype, optional: optional)
        
        // variable
        let varType: GRPHType
        if par.optional {
            if defaults[i] != nil {
                varType = par.type
            } else {
                varType = par.type.optional
            }
        } else if varargs {
            varType = par.type.inArray
        } else {
            varType = par.type
        }
        // NEW: the parameter is now declared constant
        let pvar = Variable(name: name.description, type: varType, final: true, compileTime: true)
        context.variables.append(pvar)
        
        context.generator.resolveSemanticToken(name.withType(.parameter).withModifiers([.declaration], data: .variable(pvar)))
        
        return par
    }
    
    var isExternal: Bool {
        if case .external = generated?.storage {
            return true
        }
        return false
    }
}
