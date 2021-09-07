//
//  FunctionDeclarationBlock.swift
//  File
//
//  Created by Emil Pedersen on 06/09/2021.
//

import Foundation
import GRPHLexer
import GRPHValues

extension FunctionDeclarationBlock {
    /// - Note: Tokens must be stripped
    convenience init(lineNumber: Int, context: inout CompilingContext, tokens: [Token]) throws {
        self.init(lineNumber: lineNumber)
        let context = createContext(&context)
        // syntax:
        // returnType funcName[]
        // returnType funcName[] = defaultValueExpr
        guard let paramsIndex = tokens.firstIndex(where: { $0.tokenType == .squareBrackets }),
              paramsIndex >= 2 else {
            throw DiagnosticCompileError(notice: Notice(token: Token(compound: tokens, type: .squareBrackets), severity: .error, source: .generator, message: "Could not parse function declaration, expected syntax 'returnType funcName[...]'"))
        }
        
        let name = tokens[paramsIndex - 1]
        // RESOLVE semantic token: function
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
        
        let returnType: GRPHType
        if tokens.count == paramsIndex + 1 {
            if let returnTypeOrAuto = returnTypeOrAuto {
                returnType = returnTypeOrAuto
            } else {
                throw DiagnosticCompileError(notice: Notice(token: typeLit, severity: .error, source: .generator, message: "Cannot infer auto type without a default return value", hint: "Insert ` = defaultValue` at the end of the line to add a default return value"))
            }
        } else {
            guard tokens[paramsIndex + 1].tokenType == .assignmentOperator else {
                throw DiagnosticCompileError(notice: Notice(token: tokens[paramsIndex + 1], severity: .error, source: .generator, message: "Expected a `=` after the function signature to define the default return value"))
            }
            guard tokens.count > paramsIndex + 2 else {
                throw DiagnosticCompileError(notice: Notice(token: tokens[paramsIndex + 1], severity: .error, source: .generator, message: "The default return value cannot be empty", hint: "Remove the `=` sign to not use any default return value"))
            }
            let drv = try context.generator.resolveExpression(tokens: Array(tokens[(paramsIndex + 2)...]), infer: returnTypeOrAuto)
            returnDefault = drv
            returnType = try returnTypeOrAuto ?? drv.getType(context: context, infer: SimpleType.mixed)
        }
        
        let params = tokens[paramsIndex].children.stripped.split(on: .comma)
        var varargs = false
        defaults = .init(repeating: nil, count: params.count)
        var pars: [Parameter] = []
        pars.reserveCapacity(params.count)
        for (i, param) in params.enumerated() {
            let equal = param.firstIndex(where: { $0.tokenType == .assignmentOperator }) ?? param.endIndex
            guard equal >= 2 else {
                throw DiagnosticCompileError(notice: Notice(token: Token(compound: param, type: .squareBrackets), severity: .error, source: .generator, message: "Expected parameter to have a type and name"))
            }
            
            let last = param[equal - 1]
            let optional: Bool
            let name: Token
            if last.tokenType == .varargs {
                guard i == params.count - 1 else {
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
            
            // RESOLVE semantic token: variable
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
            
            let ptype: GRPHType
            if equal < param.endIndex - 1 {
                let exp = try context.generator.resolveExpression(tokens: Array(param[(equal + 1)...]), infer: ptypeOrAuto)
                defaults[i] = exp
                ptype = try ptypeOrAuto ?? exp.getType(context: context, infer: SimpleType.mixed)
            } else if equal == param.endIndex {
                guard let ptypeOrAuto = ptypeOrAuto else {
                    throw DiagnosticCompileError(notice: Notice(token: typeLit, severity: .error, source: .generator, message: "Cannot infer parameter type without a default parameter value"))
                }
                ptype = ptypeOrAuto
            } else {
                throw DiagnosticCompileError(notice: Notice(token: param[equal], severity: .error, source: .generator, message: "Expected default parameter value after the equal sign"))
            }
            // NEW: the parameter is now declared constant
            context.variables.append(Variable(name: String(name.literal), type: ptype, final: true, compileTime: true))
            pars.append(Parameter(name: String(name.literal), type: ptype, optional: optional))
        }
        
        generated = Function(ns: NameSpaces.none, name: String(name.literal), parameters: pars, returnType: returnType, varargs: varargs, storage: .block(self))
        context.imports.append(generated)
    }
}