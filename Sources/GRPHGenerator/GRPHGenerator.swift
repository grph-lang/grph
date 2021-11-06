//
//  GRPHGenerator.swift
//  GRPH Generator
//
//  Created by Emil Pedersen on 04/09/2021.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import GRPHLexer
import GRPHValues

public class GRPHGenerator: GRPHCompilerProtocol {
    public var imports: [Importable] = [NameSpaces.namespace(named: "standard")!]
    
    public var hasStrictUnboxing: Bool = false
    public var hasStrictBoxing: Bool = false
    
    public var lines: [Token]
    
    public var lineNumber = 0
    
    var blockCount = 0
    public var instructions: [Instruction] = []
    
    var nextLabel: Token?
    
    public var context: CompilingContext!
    
    public var diagnostics: [Notice] = []
    
    /// To start capturing semantic tokens, set this to an empty array. If nil, none will be captured.
    public var resolvedSemanticTokens: [SemanticToken]?
    public var ignoreErrors = false
    
    public init(lines: [Token]) {
        self.lines = lines
    }
    
    public func compile() -> Bool {
        context = TopLevelCompilingContext(compiler: self)
        for line in lines {
            let trimmed = trimUselessStuff(children: line.children)
            guard trimmed.count > 0 else {
                // nothing significant other than indent. do not even close blocks.
                continue
            }
            guard case .integer(let indent) = line.children[0].data else {
                preconditionFailure("First token in line must always be indent with integer associated data")
            }
            self.lineNumber = line.lineNumber
            closeBlocks(tabs: indent)
            
            do {
                if let resolved = try resolveInstruction(children: trimmed) {
                    if !resolved.notABlock,
                       let block = resolved.instruction as? BlockInstruction {
                        try addBlock(block)
                    } else if let nextLabel = nextLabel {
                        throw DiagnosticCompileError(notice: Notice(token: nextLabel, severity: .error, source: .generator, message: "Labels must precede a block"))
                    } else {
                        try addInstruction(resolved.instruction)
                    }
                }
            } catch let error as DiagnosticCompileError {
                if ignoreErrors {
                    continue
                }
                diagnostics.append(error.notice)
                context = nil
                return false
            } catch let error as GRPHCompileError {
                if ignoreErrors {
                    continue
                }
                // no more specific error: add this fallback diagnostic
                if !diagnostics.contains(where: { $0.token.lineNumber == lineNumber && $0.severity == .error }) {
                    diagnostics.append(Notice(token: line, severity: .error, source: .generator, message: "\(error.type.rawValue)Error: \(error.message)"))
                }
                context = nil
                return false
            } catch {
                diagnostics.append(Notice(token: line, severity: .error, source: .generator, message: "An internal error occured while parsing this line: \(type(of: error))", hint: error.localizedDescription))
                print("NativeError; line \(lineNumber + 1)")
                print(error.localizedDescription)
                context = nil
                return false
            }
        }
        closeBlocks(tabs: 0)
        context = nil
        return !diagnostics.contains(where: { $0.severity == .error })
    }
    
    func resolveSemanticToken(_ token: @autoclosure () -> SemanticToken) {
        resolvedSemanticTokens?.append(token())
    }
    
    func resolveSemanticTokensAsModification(_ slice: ArraySlice<Token>) {
        assert(!slice.isEmpty, "empty lvalue should never get resolved")
        resolvedSemanticTokens = resolvedSemanticTokens?.map { st in
            if st.token.lineNumber == slice.first!.lineNumber,
               slice.first!.literal.startIndex <= st.token.literal.startIndex,
               st.token.literal.endIndex <= slice.last!.literal.endIndex {
                var copy = st
                copy.modifiers.insert(.modification)
                return copy
            } else {
                return st
            }
        }
    }
    
    func resolveInstruction(children: [Token]) throws -> ResolvedInstruction? {
        // children is guaranteed to be non empty. it is trimmed, so stripping it only removes whitespaces in between two tokens
        let tokens = children.stripped
        
        if children[0].tokenType == .commandName {
            let cmd = children[0]
            switch cmd.literal {
            case "#":
                if let bang = tokens[safeExact: 1],
                   bang.literal.hasPrefix("!") {
                    // shebang
                    return nil // normal
                } else {
                    throw DiagnosticCompileError(notice: Notice(token: cmd, severity: .error, source: .generator, message: "A command name can't be empty", hint: "Did you mean to comment this line? Use '//'"))
                }
            case "#import", "#using":
                let ns: NameSpace
                let member: Token
                if tokens.count == 4 || tokens.count >= 6 { // #import ns>member || #import ns>type.method
                    guard tokens[2].literal == ">" else {
                        throw DiagnosticCompileError(notice: Notice(token: tokens[2], severity: .error, source: .generator, message: "Expected `>` in namespaced member"))
                    }
                    guard let namespace = NameSpaces.namespace(named: String(tokens[1].literal)) else {
                        throw DiagnosticCompileError(notice: Notice(token: tokens[2], severity: .error, source: .generator, message: "Namespace `\(tokens[1].literal)` was not found"))
                    }
                    resolveSemanticToken(tokens[1].withType(.namespace).withModifiers([]))
                    ns = namespace
                    if tokens.count == 4 {
                        member = tokens[3]
                    } else { // method import
                        guard tokens[tokens.count - 2].tokenType == .dot else {
                            throw DiagnosticCompileError(notice: Notice(token: tokens[tokens.count - 2], severity: .error, source: .generator, message: "Expected a dot in `#import namespaceName>typeIdentifier.methodName` syntax"))
                        }
                        let typeToken = Token(compound: Array(tokens[3...(tokens.count - 3)]), type: .type)
                        resolveSemanticToken(typeToken.withModifiers([]))
                        guard let type = GRPHTypes.parse(context: context, literal: String(typeToken.literal)) else {
                            throw DiagnosticCompileError(notice: Notice(token: typeToken, severity: .error, source: .generator, message: "Could not parse type `\(typeToken.literal)`"))
                        }
                        guard let m = Method(imports: [], namespace: ns, name: String(tokens[tokens.count - 1].literal), inType: type) else {
                            throw DiagnosticCompileError(notice: Notice(token: tokens[tokens.count - 1], severity: .error, source: .generator, message: "Could not find method '\(tokens[tokens.count - 2].literal)' in type '\(type)'"))
                        }
                        resolveSemanticToken(tokens[tokens.count - 1].withType(.method).withModifiers(.defaultLibrary, data: .method(m)))
                        imports.append(m)
                        return nil
                    }
                } else if tokens.count == 2 { // #import member
                    ns = NameSpaces.none
                    member = tokens[1]
                } else {
                    throw DiagnosticCompileError(notice: Notice(token: cmd, severity: .error, source: .generator, message: "`#import` needs an argument: What namespace do you want to import?"))
                }
                let memberLiteral = String(member.literal)
                if ns.isEqual(to: NameSpaces.none) {
                    if let ns = NameSpaces.namespace(named: memberLiteral) {
                        resolveSemanticToken(member.withType(.namespace).withModifiers([]))
                        imports.append(ns)
                    } else {
                        throw DiagnosticCompileError(notice: Notice(token: member, severity: .error, source: .generator, message: "Namespace `\(memberLiteral)` was not found"))
                    }
                } else if let f = Function(imports: [], namespace: ns, name: memberLiteral) {
                    resolveSemanticToken(member.withType(.function).withModifiers(.defaultLibrary, data: .function(f)))
                    imports.append(f)
                } else if let t = ns.exportedTypes.first(where: { $0.string == memberLiteral }) {
                    resolveSemanticToken(member.withType(.type).withModifiers(.defaultLibrary))
                    imports.append(t)
                } else if let t = ns.exportedTypeAliases.first(where: { $0.name == memberLiteral }) {
                    resolveSemanticToken(member.withType(.type).withModifiers(.defaultLibrary))
                    imports.append(t)
                } else {
                    throw DiagnosticCompileError(notice: Notice(token: member, severity: .error, source: .generator, message: "Could not find member '\(memberLiteral)' in namespace '\(ns.name)'"))
                }
                return nil
            case "#typealias":
                guard tokens.count >= 3 else {
                    throw DiagnosticCompileError(notice: Notice(token: cmd, severity: .error, source: .generator, message: "`#typealias` needs two arguments: #typealias newname existingType"))
                }
                let typeToken = Token(compound: Array(tokens[2...(tokens.count - 1)]), type: .type)
                guard let type = GRPHTypes.parse(context: context, literal: String(typeToken.literal)) else {
                    throw DiagnosticCompileError(notice: Notice(token: typeToken, severity: .error, source: .generator, message: "Could not find type `\(typeToken.literal)`"))
                }
                resolveSemanticToken(tokens[1].withType(.type).withModifiers([.declaration, .definition]))
                resolveSemanticToken(typeToken.withModifiers(.defaultLibrary))
                let newname = String(tokens[1].literal)
                guard GRPHTypes.parse(context: context, literal: newname) == nil else {
                    throw DiagnosticCompileError(notice: Notice(token: tokens[1], severity: .error, source: .generator, message: "Cannot override existing type `\(newname)` with a typealias"))
                }
                switch newname {
                case "file", "image", "Image", "auto", "type",
                     "final", "global", "static", "public", "private", "protected",
                     "dict", "set", "tuple":
                    throw DiagnosticCompileError(notice: Notice(token: tokens[1], severity: .error, source: .generator, message: "Type name '\(newname)' is reserved and can't be used as a typealias name"))
                case VariableDeclarationInstruction.varNameRequirement:
                    break
                default:
                    throw DiagnosticCompileError(notice: Notice(token: tokens[1], severity: .error, source: .generator, message: "Type name '\(newname)' is not a valid type name"))
                }
                if newname.hasSuffix("Error") || newname.hasSuffix("Exception") {
                    throw DiagnosticCompileError(notice: Notice(token: tokens[1], severity: .error, source: .generator, message: "Type name '\(newname)' is reserved and can't be used as a typealias name"))
                }
                imports.append(TypeAlias(name: newname, type: type))
                return nil
            case "#if":
                if context is SwitchCompilingContext {
                    throw DiagnosticCompileError(notice: Notice(token: cmd, severity: .error, source: .generator, message: "Expected #case or #default in #switch block"))
                }
                if tokens.count == 1 {
                    throw DiagnosticCompileError(notice: Notice(token: cmd, severity: .error, source: .generator, message: "#if requires an argument of type boolean"))
                }
                return try ResolvedInstruction(instruction: IfBlock(lineNumber: lineNumber, compiler: self, condition: resolveExpression(tokens: Array(tokens.dropFirst()), infer: SimpleType.boolean)))
                
            case "#elseif", "#elif":
                if let ctx = context as? SwitchCompilingContext {
                    guard ctx.state == .next else {
                        throw DiagnosticCompileError(notice: Notice(token: cmd, severity: .error, source: .generator, message: "Expected #case or #default in #switch block"))
                    }
                    // we can allow it here, it is harmless
                }
                if tokens.count == 1 {
                    throw DiagnosticCompileError(notice: Notice(token: cmd, severity: .error, source: .generator, message: "#elseif requires an argument of type boolean"))
                }
                return try ResolvedInstruction(instruction: ElseIfBlock(lineNumber: lineNumber, compiler: self, condition: resolveExpression(tokens: Array(tokens.dropFirst()), infer: SimpleType.boolean)))
            case "#else":
                if context is SwitchCompilingContext {
                    throw DiagnosticCompileError(notice: Notice(token: cmd, severity: .error, source: .generator, message: "Expected #case or #default in #switch block"))
                }
                if tokens.count > 1 {
                    throw DiagnosticCompileError(notice: Notice(token: Token(compound: Array(tokens.dropFirst()), type: .squareBrackets), severity: .error, source: .generator, message: "#else doesn't expect arguments"))
                }
                return ResolvedInstruction(instruction: ElseBlock(compiler: self, lineNumber: lineNumber))
            case "#while":
                if tokens.count == 1 {
                    throw DiagnosticCompileError(notice: Notice(token: cmd, severity: .error, source: .generator, message: "#while requires an argument of type boolean"))
                }
                return try ResolvedInstruction(instruction: WhileBlock(lineNumber: lineNumber, compiler: self, condition: resolveExpression(tokens: Array(tokens.dropFirst()), infer: SimpleType.boolean)))
            case "#foreach":
                let split = tokens.dropFirst().split(on: .methodCallOperator)
                guard split.count == 2 else {
                    throw DiagnosticCompileError(notice: Notice(token: cmd, severity: .error, source: .generator, message: "Could not resolve foreach syntax, '#foreach varName : array' expected"))
                }
                let variable: Token
                let inOut: Bool
                switch split[0] {
                case TokenMatcher("&", .type(.identifier)):
                    inOut = true
                    variable = split[0][1]
                case TokenMatcher(.type(.identifier)):
                    inOut = false
                    variable = split[0][0]
                default:
                    throw DiagnosticCompileError(notice: Notice(token: Token(compound: split[0], type: .squareBrackets), severity: .error, source: .generator, message: "Expected a variable name in '#foreach' syntax"))
                }
                defer {
                    resolveSemanticToken(variable.withType(.variable).withModifiers([.declaration, .definition, inOut ? .none : .readonly], data: (context as? BlockCompilingContext)?.variables.first(where: { $0.name ==  variable.description }).map({ SemanticToken.AssociatedData.variable($0)})))
                }
                return try ResolvedInstruction(instruction: ForEachBlock(lineNumber: lineNumber, compiler: self, inOut: inOut, varName: variable.description, array: resolveExpression(tokens: split[1], infer: SimpleType.mixed.inArray)))
            case "#try":
                return ResolvedInstruction(instruction: TryBlock(compiler: self, lineNumber: lineNumber))
            case "#catch":
                let split = tokens.dropFirst().split(on: .methodCallOperator)
                guard split.count == 2 else {
                    throw DiagnosticCompileError(notice: Notice(token: cmd, severity: .error, source: .generator, message: "Could not resolve catch syntax, '#catch varName : errortype' expected"))
                }
                let variable = Token(compound: split[0], type: .variable)
                let name = variable.description
                let exs = split[1].split(whereSeparator: { $0.literal == "|" })
                let trm = try findTryBlock()
                let currblock = currentBlock
                var tr: TryBlock
                if let currblock = currblock {
                    tr = currblock.children[currblock.children.count - trm] as! TryBlock
                } else {
                    tr = instructions[instructions.count - trm] as! TryBlock
                }
                let block = try CatchBlock(lineNumber: lineNumber, compiler: self, varName: name)
                
                resolveSemanticToken(variable.withModifiers([.declaration, .definition, .readonly], data: (context as? BlockCompilingContext)?.variables.first(where: { $0.name ==  variable.description }).map({ SemanticToken.AssociatedData.variable($0)})))
                
                for rawErr in exs {
                    let terror = Token(compound: Array(rawErr), type: .type)
                    let error = terror.description
                    resolveSemanticToken(terror.withModifiers(.defaultLibrary))
                    if error == "Exception" {
                        tr.catches[nil] = block
                        block.addError(type: "Exception")
                    } else if error.hasSuffix("Exception"),
                              let err = GRPHRuntimeError.RuntimeExceptionType(rawValue: String(error.dropLast(9))) {
                        guard tr.catches[err] == nil else {
                            continue
                        }
                        tr.catches[err] = block
                        block.addError(type: "\(err.rawValue)Exception")
                    } else {
                        throw GRPHCompileError(type: .undeclared, message: "Error '\(error)' not found")
                    }
                }
                if let currblock = currblock {
                    currentBlock!.children[currblock.children.count - trm] = tr
                } else {
                    instructions[instructions.count - trm] = tr
                }
                return ResolvedInstruction(instruction: block)
            case "#throw":
                guard TokenMatcher(types: .commandName, .identifier, .parentheses).matches(tokens: tokens) else {
                    throw DiagnosticCompileError(notice: Notice(token: cmd, severity: .error, source: .generator, message: "Could not resolve throw syntax, '#throw errorType(message)' expected"))
                }
                let err = tokens[1]
                resolveSemanticToken(err.withType(.type).withModifiers([.defaultLibrary, .call])) // constructor if they are changed to real ones, one day
                guard err.literal.hasSuffix("Exception"),
                      let error = GRPHRuntimeError.RuntimeExceptionType(rawValue: String(err.literal.dropLast(9))) else {
                    throw DiagnosticCompileError(notice: Notice(token: err, severity: .error, source: .generator, message: "Could not find error type '\(err.literal)'"))
                }
                let msg = try resolveExpression(tokens: tokens[2].children, infer: SimpleType.string)
                guard try SimpleType.string.isInstance(context: context, expression: msg) else {
                    throw DiagnosticCompileError(notice: Notice(token: tokens[2], severity: .error, source: .generator, message: "Expected the message to be a string"))
                }
                return ResolvedInstruction(instruction: ThrowInstruction(lineNumber: lineNumber, type: error, message: msg))
            case "#function":
                return try ResolvedInstruction(instruction: FunctionDeclarationBlock(lineNumber: lineNumber, compiler: self, tokens: Array(tokens.dropFirst())))
            case "#return":
                guard let block = context.inFunction else {
                    throw DiagnosticCompileError(notice: Notice(token: cmd, severity: .error, source: .generator, message: "#return may only be used in functions"))
                }
                
                let params = Array(tokens.dropFirst())
                if block.generated.returnType.isTheVoid {
                    guard params.isEmpty else {
                        throw DiagnosticCompileError(notice: Notice(token: Token(compound: params, type: .squareBrackets), severity: .error, source: .generator, message: "No return value expected in void function declaration"))
                    }
                    return ResolvedInstruction(instruction: ReturnInstruction(lineNumber: lineNumber, value: nil))
                } else if params.isEmpty {
                    if block.returnDefault == nil {
                        throw DiagnosticCompileError(notice: Notice(token: cmd, severity: .error, source: .generator, message: "Expected a return value in non-void function declaration"))
                    } else {
                        return ResolvedInstruction(instruction: ReturnInstruction(lineNumber: lineNumber, value: nil))
                    }
                } else {
                    let expected = block.generated.returnType
                    let exp = try GRPHTypes.autobox(context: context, expression: resolveExpression(tokens: params, infer: expected), expected: expected)
                    guard try block.generated.returnType.isInstance(context: context, expression: exp) else {
                        throw GRPHCompileError(type: .parse, message: "Expected a #return value of type \(expected), found a \(try exp.getType(context: context, infer: expected))")
                    }
                    return ResolvedInstruction(instruction: ReturnInstruction(lineNumber: lineNumber, value: exp))
                }
            case "#break":
                return try ResolvedInstruction(instruction: BreakInstruction(lineNumber: lineNumber, type: .break, scope: .parse(tokens: tokens.dropFirst())))
            case "#continue":
                return try ResolvedInstruction(instruction: BreakInstruction(lineNumber: lineNumber, type: .continue, scope: .parse(tokens: tokens.dropFirst())))
            case "#fall":
                return try ResolvedInstruction(instruction: BreakInstruction(lineNumber: lineNumber, type: .fall, scope: .parse(tokens: tokens.dropFirst())))
            case "#fallthrough":
                return try ResolvedInstruction(instruction: BreakInstruction(lineNumber: lineNumber, type: .fallthrough, scope: .parse(tokens: tokens.dropFirst())))
            case "#block":
                return ResolvedInstruction(instruction: SimpleBlockInstruction(compiler: self, lineNumber: lineNumber))
            case "#requires":
                let version: Version
                if tokens.count == 2 {
                    version = Version()
                } else if tokens.count == 3 {
                    guard let v = Version(description: String(tokens[2].literal)) else {
                        throw DiagnosticCompileError(notice: Notice(token: tokens[2], severity: .error, source: .generator, message: "Couldn't parse version number '\(tokens[2].literal)'"))
                    }
                    version = v
                } else {
                    throw DiagnosticCompileError(notice: Notice(token: cmd, severity: .error, source: .generator, message: "Expected syntax '#requires plugin version'"))
                }
                resolveSemanticToken(tokens[1].withType(.keyword).withModifiers([]))
                let requires = RequiresInstruction(lineNumber: lineNumber, plugin: String(tokens[1].literal), version: version)
                if blockCount == 0 {
                    try requires.run(context: context)
                    return nil
                } else {
                    return ResolvedInstruction(instruction: requires)
                }
            case "#switch":
                if let nextLabel = nextLabel {
                    throw DiagnosticCompileError(notice: Notice(token: nextLabel, severity: .error, source: .generator, message: "A #switch block cannot have a label", hint: "Put the label on the cases instead"))
                }
                
                var name: String
                var n = 0
                repeat {
                    name = "$_switch\(n)$"
                    n += 1
                } while context.findVariable(named: name) != nil
                
                let exp = try resolveExpression(tokens: Array(tokens.dropFirst()), infer: nil)
                let type = try exp.getType(context: context, infer: SimpleType.mixed)
                // We declare our variable
                try addInstruction(VariableDeclarationInstruction(lineNumber: lineNumber, global: false, constant: true, type: type, name: name, value: exp))
                try addBlock(SwitchTransparentBlock(lineNumber: lineNumber))
                // We create our context, denying non-#case/#default and advertising our var name
                context = SwitchCompilingContext(parent: context, compare: VariableExpression(name: name))
                // We advertise our var with its type, so type checks in #case works
                context.addVariable(Variable(name: name, type: type, final: true, compileTime: true), global: false)
                return nil // handled
            case "#case": // uwu
                guard let ctx = context as? SwitchCompilingContext else {
                    throw DiagnosticCompileError(notice: Notice(token: cmd, severity: .error, source: .generator, message: "#case cannot be used outside of a #switch"))
                }
                let type = try ctx.compare.getType(context: context, infer: SimpleType.mixed)
                // children instead of tokens as we need the spaces
                let params = children.dropFirst().split(on: .whitespace)
                guard params.count > 0 else {
                    throw DiagnosticCompileError(notice: Notice(token: cmd, severity: .error, source: .generator, message: "#case needs at least an argument"))
                }
                let exps = try params.map { try resolveExpression(tokens: $0, infer: type) }
                    .map { try BinaryExpression(context: ctx, left: ctx.compare, op: "==", right: $0) }
                let combined = try exps.reduce(into: nil) { (into: inout Expression?, curr: BinaryExpression) in
                    if let last = into {
                        into = try BinaryExpression(context: ctx, left: last, op: "||", right: curr)
                    } else {
                        into = curr
                    }
                }!
                
                switch ctx.state {
                case .first:
                    ctx.state = .next
                    return try ResolvedInstruction(instruction: IfBlock(lineNumber: lineNumber, compiler: self, condition: combined))
                case .next:
                    return try ResolvedInstruction(instruction: ElseIfBlock(lineNumber: lineNumber, compiler: self, condition: combined))
                case .last:
                    throw DiagnosticCompileError(notice: Notice(token: cmd, severity: .error, source: .generator, message: "#case must come before the terminating #default case in a #switch"))
                }
            case "#default":
                guard let ctx = context as? SwitchCompilingContext else {
                    throw GRPHCompileError(type: .parse, message: "#default cannot be used outside of a #switch")
                }
                if tokens.count > 1 {
                    throw DiagnosticCompileError(notice: Notice(token: Token(compound: Array(tokens.dropFirst()), type: .squareBrackets), severity: .error, source: .generator, message: "#default doesn't expect arguments"))
                }
                switch ctx.state {
                case .first:
                    throw DiagnosticCompileError(notice: Notice(token: cmd, severity: .error, source: .generator, message: "#default cannot be first in a #switch, it must be last"))
                case .next:
                    ctx.state = .last
                    return ResolvedInstruction(instruction: ElseBlock(compiler: self, lineNumber: lineNumber))
                case .last:
                    throw DiagnosticCompileError(notice: Notice(token: cmd, severity: .error, source: .generator, message: "Cannot put multiple #default cases in a #switch"))
                }
            case "#compiler":
                guard tokens.count == 3 || (tokens.count > 3 && tokens[1].literal == "indent") else {
                    throw DiagnosticCompileError(notice: Notice(token: cmd, severity: .error, source: .generator, message: "Expected syntax '#compiler key value'"))
                }
                resolveSemanticToken(tokens[1].withType(.keyword).withModifiers([]))
                switch tokens[1].literal {
                case "indent", "altBrackets", "altBracketSet", "alternativeBracketSet":
                    return nil // handled by the lexer
                case "strict", "strictUnbox", "strictUnboxing", "noAutoUnbox":
                    guard let value = Bool(String(tokens[2].literal)) else {
                        throw DiagnosticCompileError(notice: Notice(token: tokens[2], severity: .error, source: .generator, message: "Expected value to be a boolean literal"))
                    }
                    hasStrictUnboxing = value
                case "strictBoxing", "noAutobox", "noAutoBox":
                    guard let value = Bool(String(tokens[2].literal)) else {
                        throw DiagnosticCompileError(notice: Notice(token: tokens[2], severity: .error, source: .generator, message: "Expected value to be a boolean literal"))
                    }
                    hasStrictBoxing = value
                case "strictest":
                    guard let value = Bool(String(tokens[2].literal)) else {
                        throw DiagnosticCompileError(notice: Notice(token: tokens[2], severity: .error, source: .generator, message: "Expected value to be a boolean literal"))
                    }
                    hasStrictUnboxing = value
                    hasStrictBoxing = value
                case "ignore":
                    resolveSemanticToken(tokens[2].withType(.keyword).withModifiers([]))
                    switch tokens[2].literal {
                    case "errors", "Error":
                        ignoreErrors = true
                    case "reset", "nothing":
                        ignoreErrors = false
                    default:
                        throw DiagnosticCompileError(notice: Notice(token: tokens[2], severity: .error, source: .generator, message: "Expected value to be 'errors' or 'reset'"))
                    }
                default:
                    throw DiagnosticCompileError(notice: Notice(token: tokens[1], severity: .error, source: .generator, message: "Unknown compiler key"))
                }
                return nil
            case "#goto":
                throw DiagnosticCompileError(notice: Notice(token: cmd, severity: .error, source: .generator, message: "#goto has been removed"))
            case "#setting":
                diagnostics.append(Notice(token: cmd, severity: .warning, source: .generator, message: "#setting isn't available in this version of GRPH"))
                return nil
            default:
                // note: #type has been removed
                diagnostics.append(Notice(token: cmd, severity: .warning, source: .generator, message: "Unknown command '\(cmd.literal)'"))
                return nil
            }
        } else if children[0].tokenType == .labelPrefixOperator {
            guard tokens.count == 2, tokens[1].tokenType == .label else {
                throw DiagnosticCompileError(notice: Notice(token: children[0], severity: .error, source: .generator, message: "Invalid label, expected label identifier"))
            }
            nextLabel = tokens[1]
            return nil
        } else {
            // simple assignment, variable declaration, inline function, array modification
            if let assignment = tokens.firstIndex(where: { $0.tokenType == .assignmentOperator }),
               assignment > 0 {
                let last = tokens[assignment - 1]
                if last.tokenType == .curlyBraces { // array modification
                    // WE COULD ALLOW ANY (ASSIGNABLE) EXPRESSION INSTEAD OF JUST VARIABLES YAY
                    guard assignment == 2, tokens[0].tokenType == .identifier else {
                        throw DiagnosticCompileError(notice: Notice(token: Token(compound: Array(tokens[0..<(assignment - 1)]), type: .squareBrackets), severity: .error, source: .generator, message: "Expected array modification subject to be a variable"))
                    }
                    let varName = tokens[0].description
                    let curly = last.children.stripped
                    
                    resolveSemanticToken(tokens[0].withType(.variable).withModifiers([.modification], data: context.findVariable(named: varName).map({ SemanticToken.AssociatedData.variable($0)})))
                    
                    guard let indexLast = curly.last else {
                        throw DiagnosticCompileError(notice: Notice(token: last, severity: .error, source: .generator, message: "Index or operation required in array modification instruction"))
                    } // -, +, = or ignore
                    let index: [Token]
                    let type: ArrayModificationInstruction.ArrayModificationOperation
                    switch indexLast.literal {
                    case "=":
                        index = Array(curly.dropLast())
                        type = .set
                    case "-":
                        index = Array(curly.dropLast())
                        type = .remove
                    case "+":
                        index = Array(curly.dropLast())
                        type = .add
                    default:
                        index = curly
                        type = .set
                    }
                    
                    guard let assignedTo = context.findVariable(named: varName) else {
                        throw DiagnosticCompileError(notice: Notice(token: tokens[0], severity: .error, source: .generator, message: "Could not find variable '\(varName)' in scope"))
                    }
                    guard let arr = assignedTo.type as? ArrayType else {
                        throw DiagnosticCompileError(notice: Notice(token: tokens[0], severity: .error, source: .generator, message: "The type of the variable in an array modification instruction must be an array"))
                    }
                    
                    let value: Expression?
                    if assignment == tokens.endIndex - 1 {
                        value = nil
                    } else {
                        value = try resolveExpression(tokens: Array(tokens[(assignment + 1)...]), infer: arr.content)
                    }
                    let indexExp: Expression?
                    if index.isEmpty {
                        indexExp = nil
                    } else {
                        indexExp = try GRPHTypes.autobox(context: context, expression: resolveExpression(tokens: index, infer: SimpleType.integer), expected: SimpleType.integer)
                    }
                    return try ResolvedInstruction(instruction: ArrayModificationInstruction(lineNumber: lineNumber, context: context, name: varName, op: type, index: indexExp, value: value))
                } else if last.tokenType == .squareBrackets { // inline function
                    let restore = context!
                    defer {
                        // do not modify external context, this isn't a block
                        context = restore
                    }
                    return try ResolvedInstruction(instruction: FunctionDeclarationBlock(lineNumber: lineNumber, compiler: self, tokens: tokens), notABlock: true)
                } else {
                    guard assignment < tokens.endIndex - 1 else {
                        throw DiagnosticCompileError(notice: Notice(token: tokens[assignment], severity: .error, source: .generator, message: "Assignment value cannot be empty"))
                    }
                    // var declaration or assignment, try assignment first
                    if let assigned = try? resolveExpression(tokens: Array(tokens[..<assignment]), infer: nil) as? AssignableExpression {
                        resolveSemanticTokensAsModification(tokens[..<assignment])
                        let type = try assigned.getType(context: context, infer: SimpleType.mixed)
                        let value = try resolveExpression(tokens: Array(tokens[(assignment + 1)...]), infer: type)
                        return try ResolvedInstruction(instruction: AssignmentInstruction(lineNumber: lineNumber, context: context, assigned: assigned, op: nil, value: value))
                    } else { // var declaration
                        guard last.tokenType == .identifier else {
                            throw DiagnosticCompileError(notice: Notice(token: tokens[assignment], severity: .error, source: .generator, message: "Expected variable name or valid assignable expression"))
                        }
                        
                        var offset = 0
                        var global = false
                        var final = false
                        if tokens[offset].literal == "global" {
                            global = true
                            offset += 1
                        }
                        if tokens[offset].literal == "final" {
                            final = true
                            offset += 1
                            if tokens[offset].literal == "global" && !global {
                                // non blocking error
                                diagnostics.append(Notice(token: tokens[offset], severity: .error, source: .generator, message: "'global' must precede 'final'"))
                                global = true
                                offset += 1
                            }
                        }
                        let typeLit = Token(compound: Array(tokens[offset..<(assignment - 1)]), type: .type)
                        let typeOrAuto: GRPHType?
                        if typeLit.literal == "auto" {
                            typeOrAuto = nil
                        } else if let type = GRPHTypes.parse(context: context, literal: String(typeLit.literal)) {
                            typeOrAuto = type
                        } else {
                            throw DiagnosticCompileError(notice: Notice(token: typeLit, severity: .error, source: .generator, message: "Could not find type '\(typeLit.literal)'"))
                        }
                        resolveSemanticToken(typeLit.withModifiers([]))
                        defer {
                            resolveSemanticToken(last.withType(.variable).withModifiers([.declaration, .definition, final ? .readonly : .none], data: context.findVariable(named: last.description).map({ SemanticToken.AssociatedData.variable($0)})))
                        }
                        
                        let exp = try resolveExpression(tokens: Array(tokens[(assignment + 1)...]), infer: typeOrAuto)
                        
                        return try ResolvedInstruction(instruction: VariableDeclarationInstruction(lineNumber: lineNumber, context: context, global: global, constant: final, typeOrAuto: typeOrAuto, name: last.description, exp: exp))
                    }
                }
            } else if let compound = tokens.firstIndex(where: { $0.tokenType == .assignmentCompound }) {
                guard let assigned = try resolveExpression(tokens: Array(tokens[..<compound]), infer: nil) as? AssignableExpression else {
                    throw DiagnosticCompileError(notice: Notice(token: Token(compound: Array(tokens[..<compound]), type: .squareBrackets), severity: .error, source: .generator, message: "Left value of an assignment must be assignable"))
                }
                resolveSemanticTokensAsModification(tokens[..<compound])
                let type = try assigned.getType(context: context, infer: SimpleType.mixed)
                let value = try resolveExpression(tokens: Array(tokens[(compound + 1)...]), infer: type)
                return try ResolvedInstruction(instruction: AssignmentInstruction(lineNumber: lineNumber, context: context, assigned: assigned, op: tokens[compound].children[0].description, value: value))
            } else if let colon = tokens.firstIndex(where: { $0.tokenType == .methodCallOperator }), colon > 0 {
                // functionName: arg1 arg2
                // methodExecutedOnThis: arg1 arg2
                // methodName subjectExp: arg1 arg2
                let ns: NameSpace
                let name: Token
                let offset: Int
                if TokenMatcher(.type(.identifier), .literal(">"), .type(.identifier)).matches(tokens: tokens.prefix(3)) {
                    guard let namespace = NameSpaces.namespace(named: tokens[0].description) else {
                        throw DiagnosticCompileError(notice: Notice(token: tokens[0], severity: .error, source: .generator, message: "Could not find namespace '\(tokens[0].literal)'"))
                    }
                    resolveSemanticToken(tokens[0].withType(.namespace).withModifiers([]))
                    ns = namespace
                    name = tokens[2]
                    offset = 3
                } else if tokens[0].tokenType == .identifier {
                    ns = NameSpaces.none
                    name = tokens[0]
                    offset = 1
                } else {
                    throw DiagnosticCompileError(notice: Notice(token: tokens[0], severity: .error, source: .generator, message: "Expected method/function name"))
                }
                let unstrippedColon = children.firstIndex(where: { $0.tokenType == .methodCallOperator })!
                let args = try children[(unstrippedColon + 1)...].split(on: .whitespace).map { literal in
                    try resolveExpression(tokens: literal, infer: nil)
                }
                if offset < colon {
                    // A method on some subject
                    let subject = try resolveExpression(tokens: Array(tokens[offset..<colon]), infer: nil)
                    let type = try subject.getType(context: context, infer: SimpleType.mixed)
                    guard let method = Method(imports: imports, namespace: ns, name: name.description, inType: type) else {
                        throw DiagnosticCompileError(notice: Notice(token: name, severity: .error, source: .generator, message: "Could not find method '\(name.literal)' in type '\(type.string)'"))
                    }
                    resolveSemanticToken(name.withType(.method).withModifiers([.defaultLibrary, .call], data: .method(method)))
                    return try ResolvedInstruction(instruction: ExpressionInstruction(lineNumber: lineNumber, expression: MethodExpression(ctx: context, method: method, on: subject, values: args, asInstruction: true)))
                } else {
                    // function, or method on 'this'
                    if let function = Function(imports: imports, namespace: ns, name: name.description) {
                        resolveSemanticToken(name.withType(.function).withModifiers([function.semantic, .call], data: .function(function)))
                        return try ResolvedInstruction(instruction: ExpressionInstruction(lineNumber: lineNumber, expression: FunctionExpression(ctx: context, function: function, values: args, asInstruction: true)))
                    } else if let method = Method(imports: imports, namespace: ns, name: name.description, inType: context.findVariable(named: "this")!.type) {
                        resolveSemanticToken(name.withType(.method).withModifiers([.defaultLibrary, .call], data: .method(method)))
                        return try ResolvedInstruction(instruction: ExpressionInstruction(lineNumber: lineNumber, expression: MethodExpression(ctx: context, method: method, on: VariableExpression(name: "this"), values: args, asInstruction: true)))
                    } else {
                        throw DiagnosticCompileError(notice: Notice(token: name, severity: .error, source: .generator, message: "Could not find function or method '\(name.literal)'"))
                    }
                }
            } else if TokenMatcher(.type(.identifier), .literal(">"), .type(.identifier), .type(.squareBrackets)).matches(tokens: tokens) {
                guard let ns = NameSpaces.namespace(named: tokens[0].description) else {
                    throw DiagnosticCompileError(notice: Notice(token: tokens[0], severity: .error, source: .generator, message: "Could not find namespace '\(tokens[0].literal)'"))
                }
                let name = tokens[2]
                resolveSemanticToken(tokens[0].withType(.namespace).withModifiers([]))
                guard let function = Function(imports: imports, namespace: ns, name: name.description) else {
                    throw DiagnosticCompileError(notice: Notice(token: name, severity: .error, source: .generator, message: "Could not find function '\(name.literal)' in namespace '\(ns.name)'"))
                }
                resolveSemanticToken(name.withType(.function).withModifiers([function.semantic, .call], data: .function(function)))
                return try ResolvedInstruction(instruction: ExpressionInstruction(lineNumber: lineNumber, expression: FunctionExpression(ctx: context, function: function, values: tokens[3].children.split(on: .whitespace).map { try resolveExpression(tokens: $0, infer: nil) }, asInstruction: true)))
            } else if TokenMatcher(types: .identifier, .squareBrackets).matches(tokens: tokens) {
                let name = tokens[0]
                guard let function = Function(imports: imports, namespace: NameSpaces.none, name: name.description) else {
                    throw DiagnosticCompileError(notice: Notice(token: name, severity: .error, source: .generator, message: "Could not find function '\(name.literal)' in scope"))
                }
                resolveSemanticToken(name.withType(.function).withModifiers([function.semantic, .call], data: .function(function)))
                return try ResolvedInstruction(instruction: ExpressionInstruction(lineNumber: lineNumber, expression: FunctionExpression(ctx: context, function: function, values: tokens[1].children.split(on: .whitespace).map { try resolveExpression(tokens: $0, infer: nil) }, asInstruction: true)))
            } else if TokenMatcher(types: .identifier, .lambdaHatOperator, .squareBrackets).matches(tokens: tokens) {
                resolveSemanticToken(tokens[0].withType(.variable).forVariable(context.findVariable(named: tokens[0].description)).addingModifier(.call))
                return try ResolvedInstruction(instruction: ExpressionInstruction(lineNumber: lineNumber, expression: FuncRefCallExpression(ctx: context, varName: tokens[0].description, values: tokens[2].children.split(on: .whitespace).map { try resolveExpression(tokens: $0, infer: nil) }, asInstruction: true)))
            } else if let exp = try? resolveExpression(tokens: tokens, infer: nil) as? ArrayValueExpression, exp.removing {
                return ResolvedInstruction(instruction: ExpressionInstruction(lineNumber: lineNumber, expression: exp))
            }
            throw GRPHCompileError(type: .parse, message: "Could not resolve instruction")
        }
    }
    
    public func resolveExpression(tokens _tokens: [Token], infer: GRPHType?) throws -> Expression {
        // whitespaces are never useful in individual expressions
        // they are in instructions for method calls
        // otherwise, they always will be inside .squareBrackets or .parentheses
        let tokens = _tokens.stripped
        if tokens.count == 0 {
            // this shouldn't happen. the message is vague, and we have no token to blame
            throw GRPHCompileError(type: .invalidArguments, message: "Empty expression found")
        } else if tokens.count == 1 {
            let token = tokens[0]
            switch token.tokenType {
            case .squareBrackets:
                return try resolveExpression(tokens: token.children, infer: infer)
            case .enumCase:
                let raw = String(token.literal)
                if let direction = Direction(rawValue: raw) {
                    return ConstantExpression(direction: direction)
                } else if let stroke = Stroke(rawValue: raw) {
                    return ConstantExpression(stroke: stroke)
                } else {
                    preconditionFailure(".enumCase token type can only be direction or stroke")
                }
            case .booleanLiteral:
                return ConstantExpression(boolean: token.literal == "true")
            case .nullLiteral:
                return NullExpression()
            case .numberLiteral:
                switch token.data {
                case .integer(let int):
                    return ConstantExpression(int: int)
                case .float(let float):
                    return ConstantExpression(float: float)
                default:
                    preconditionFailure("invalid numberLiteral token")
                }
            case .rotationLiteral:
                if case .integer(let int) = token.data {
                    return ConstantExpression(rot: Rotation(value: int))
                } else {
                    preconditionFailure("invalid rotationLiteral token")
                }
            case .posLiteral:
                if let x = token.children[0].data.asNumber,
                   let y = token.children[2].data.asNumber {
                    return ConstantExpression(pos: Pos(x: x, y: y))
                } else {
                    preconditionFailure("invalid posLiteral token")
                }
            case .stringLiteral:
                if case .string(let str) = token.data {
                    return ConstantExpression(string: str)
                } else {
                    preconditionFailure("invalid stringLiteral token")
                }
            case .parentheses:
                if let infer = infer {
                    let type = GRPHTypes.autoboxed(type: infer, expected: SimpleType.mixed)
                    let content = inferParametrableContent(type.constructor)
                    // zero-width semantic token with constructor data
                    resolveSemanticToken(Token(lineNumber: token.lineNumber, lineOffset: token.lineOffset, literal: token.literal[token.lineOffset..<token.lineOffset], tokenType: .type).withModifiers(.call, data: type.constructor.map { .constructor($0) }))
                    return try ConstructorExpression(ctx: context, type: type, values: token.children.split(on: .whitespace).map { try resolveExpression(tokens: $0, infer: content) })
                } else {
                    throw DiagnosticCompileError(notice: Notice(token: token, severity: .error, source: .generator, message: "Constructor type could not be inferred"))
                }
            case .curlyBraces:
                diagnostics.append(Notice(token: token, severity: .warning, source: .generator, message: "Array literals are deprecated", tags: [.deprecated], hint: "Use constructors instead"))
                let wrapped: GRPHType
                if let infer = infer as? ArrayType {
                    wrapped = infer.content
                } else {
                    diagnostics.append(Notice(token: token, severity: .warning, source: .generator, message: "Array literal type couldn't be inferred, assuming floats"))
                    wrapped = SimpleType.float
                }
                return try ArrayLiteralExpression(wrapped: wrapped, values: token.children.stripped.split(on: .comma).map { tokens in
                    let exp = try GRPHTypes.autobox(context: context, expression: resolveExpression(tokens: tokens, infer: wrapped), expected: wrapped)
                    let type = try exp.getType(context: context, infer: wrapped)
                    guard type.isInstance(of: wrapped) else {
                        throw DiagnosticCompileError(notice: Notice(token: Token(compound: tokens, type: .squareBrackets), severity: .error, source: .generator, message: "Value of type '\(type)' couldn't be converted to \(wrapped)"))
                    }
                    return exp
                })
            case .identifier:
                resolveSemanticToken(token.withType(.variable).forVariable(context.findVariable(named: tokens[0].description)))
                return VariableExpression(name: token.description)
            default:
                break
            }
        }
        switch tokens {
        case TokenMatcher(types: .lambdaHatOperator, .squareBrackets): // ^[...]
            return try LambdaExpression(context: context, token: tokens[1], infer: infer)
        case TokenMatcher(types: .lambdaHatOperator, .identifier): // ^funcName
            let name = String(tokens[1].literal)
            guard let function = Function(imports: context.imports, namespace: NameSpaces.none, name: name) else {
                throw DiagnosticCompileError(notice: Notice(token: tokens[1], severity: .error, source: .generator, message: "Could not find function '\(name)'"))
            }
            resolveSemanticToken(tokens[1].withType(.function).withModifiers(function.semantic, data: .function(function)))
            return try FunctionReferenceExpression(function: function, infer: infer)
        case TokenMatcher(.type(.lambdaHatOperator), .type(.identifier), ">", .type(.identifier)): // ^ns>funcName
            guard let ns = NameSpaces.namespace(named: String(tokens[1].literal)) else {
                throw DiagnosticCompileError(notice: Notice(token: tokens[1], severity: .error, source: .generator, message: "Could not find namespace '\(tokens[1].literal)'"))
            }
            let name = String(tokens[3].literal)
            resolveSemanticToken(tokens[1].withType(.namespace).withModifiers([]))
            guard let function = Function(imports: context.imports, namespace: ns, name: name) else {
                throw DiagnosticCompileError(notice: Notice(token: tokens[3], severity: .error, source: .generator, message: "Could not find function '\(name)' in namespace '\(ns.name)'"))
            }
            resolveSemanticToken(tokens[3].withType(.function).withModifiers(.defaultLibrary, data: .function(function)))
            return try FunctionReferenceExpression(function: function, infer: infer)
        case TokenMatcher(types: .identifier, .squareBrackets): // funcName[...]
            let name = String(tokens[0].literal)
            guard let function = Function(imports: context.imports, namespace: NameSpaces.none, name: name) else {
                throw DiagnosticCompileError(notice: Notice(token: tokens[0], severity: .error, source: .generator, message: "Could not find function '\(name)'"))
            }
            resolveSemanticToken(tokens[0].withType(.function).withModifiers([function.semantic, .call], data: .function(function)))
            return try FunctionExpression(ctx: context, function: function, values: tokens[1].children.split(on: .whitespace).map { try resolveExpression(tokens: $0, infer: nil) })
        case TokenMatcher(.type(.identifier), ">", .type(.identifier), .type(.squareBrackets)): // ns>funcName[...]
            guard let ns = NameSpaces.namespace(named: String(tokens[0].literal)) else {
                throw DiagnosticCompileError(notice: Notice(token: tokens[0], severity: .error, source: .generator, message: "Could not find namespace '\(tokens[0].literal)'"))
            }
            let name = String(tokens[2].literal)
            resolveSemanticToken(tokens[0].withType(.namespace).withModifiers([]))
            guard let function = Function(imports: context.imports, namespace: ns, name: name) else {
                throw DiagnosticCompileError(notice: Notice(token: tokens[2], severity: .error, source: .generator, message: "Could not find function '\(name)' in namespace '\(ns.name)'"))
            }
            resolveSemanticToken(tokens[2].withType(.function).withModifiers([.defaultLibrary, .call], data: .function(function)))
            return try FunctionExpression(ctx: context, function: function, values: tokens[3].children.split(on: .whitespace).map { try resolveExpression(tokens: $0, infer: nil) })
        case TokenMatcher(types: .identifier, .curlyBraces): // varName{...}
            resolveSemanticToken(tokens[0].withType(.variable).forVariable(context.findVariable(named: tokens[0].description)))
            let removing = tokens[1].children.last?.literal == "-"
            let children = tokens[1].children.dropLast(removing ? 1 : 0)
            return try ArrayValueExpression(context: context, varName: String(tokens[0].literal), index: children.isEmpty ? nil : resolveExpression(tokens: Array(children), infer: SimpleType.integer), removing: removing)
        case TokenMatcher(types: .identifier, .lambdaHatOperator, .squareBrackets): // varName^[...]
            resolveSemanticToken(tokens[0].withType(.variable).forVariable(context.findVariable(named: tokens[0].description)).addingModifier(.call))
            return try FuncRefCallExpression(ctx: context, varName: String(tokens[0].literal), values: tokens[2].children.split(on: .whitespace).map { try resolveExpression(tokens: $0, infer: nil) })
        default:
            break
        }
        
        if let exp = try findCast(in: tokens, infer: infer) {
            return exp
        }
        
        if tokens.last!.tokenType == .parentheses { // type(...)
            let compound = Token(compound: Array(tokens.dropLast()), type: .type)
            if compound.literal == "auto" {
                if let infer = infer {
                    let type = GRPHTypes.autoboxed(type: infer, expected: SimpleType.mixed)
                    let content = inferParametrableContent(type.constructor)
                    resolveSemanticToken(compound.withModifiers(.call, data: type.constructor.map { .constructor($0) }))
                    return try ConstructorExpression(ctx: context, type: type, values: tokens.last!.children.split(on: .whitespace).map { try resolveExpression(tokens: $0, infer: content)})
                } else {
                    throw DiagnosticCompileError(notice: Notice(token: compound, severity: .error, source: .generator, message: "Constructor type could not be inferred"))
                }
            } else if let type = GRPHTypes.parse(context: context, literal: String(compound.literal)) {
                let content = inferParametrableContent(type.constructor)
                resolveSemanticToken(compound.withModifiers(.call, data: type.constructor.map { .constructor($0) }))
                return try ConstructorExpression(ctx: context, type: type, values: tokens.last!.children.split(on: .whitespace).map { try resolveExpression(tokens: $0, infer: content)})
            } else if compound.validTypeIdentifier {
                diagnostics.append(Notice(token: compound, severity: .hint, source: .generator, message: "Couldn't parse '\(compound.literal)' as a type for constructor expression"))
            }
        }
    arrayLiteralParsing:
        if tokens.last!.tokenType == .curlyBraces { // type{...}
            let compound = Token(compound: Array(tokens.dropLast()), type: .type)
            let wrapped: GRPHType
            if compound.literal == "auto" {
                if let infer = infer as? ArrayType {
                    wrapped = infer.content
                } else {
                    diagnostics.append(Notice(token: compound, severity: .warning, source: .generator, message: "Array literal type couldn't be inferred, assuming floats"))
                    wrapped = SimpleType.float
                }
            } else if let type = GRPHTypes.parse(context: context, literal: String(compound.literal)) {
                wrapped = type
            } else if compound.validTypeIdentifier {
                diagnostics.append(Notice(token: compound, severity: .hint, source: .generator, message: "Couldn't parse '\(compound.literal)' as a type for array literal"))
                break arrayLiteralParsing
            } else {
                break arrayLiteralParsing
            }
            resolveSemanticToken(compound.withModifiers([]))
            
            diagnostics.append(Notice(token: tokens.last!, severity: .warning, source: .generator, message: "Array literals are deprecated", tags: [.deprecated], hint: "Use constructors instead"))
            
            return try ArrayLiteralExpression(wrapped: wrapped, values: tokens.last!.children.stripped.split(on: .comma).map { tokens in
                let exp = try GRPHTypes.autobox(context: context, expression: resolveExpression(tokens: tokens, infer: wrapped), expected: wrapped)
                let type = try exp.getType(context: context, infer: wrapped)
                guard type.isInstance(of: wrapped) else {
                    throw DiagnosticCompileError(notice: Notice(token: Token(compound: tokens, type: .squareBrackets), severity: .error, source: .generator, message: "Value of type '\(type)' couldn't be converted to \(wrapped)"))
                }
                return exp
            })
        }
        
        // we require exp to be one token as otherwise it'd be difficult to differenciate with the greater-than operator
        // [exp].ns>methodName[...]
        if TokenMatcher(.any, .type(.dot), .type(.identifier), ">", .type(.identifier), .type(.squareBrackets)).matches(tokens: tokens) {
            guard let ns = NameSpaces.namespace(named: String(tokens[2].literal)) else {
                throw DiagnosticCompileError(notice: Notice(token: tokens[2], severity: .error, source: .generator, message: "Could not find namespace '\(tokens[2].literal)'"))
            }
            let on = try resolveExpression(tokens: [tokens[0]], infer: nil)
            let name = tokens[4]
            resolveSemanticToken(tokens[2].withType(.namespace).withModifiers([]))
            guard let method = Method(imports: context.imports, namespace: ns, name: String(name.literal), inType: try on.getType(context: context, infer: SimpleType.mixed)) else {
                throw GRPHCompileError(type: .undeclared, message: "Undeclared method '\(try on.getType(context: context, infer: SimpleType.mixed)).\(ns.name)>\(name.literal)'")
            }
            resolveSemanticToken(name.withType(.method).withModifiers([.defaultLibrary, .call], data: .method(method)))
            return try MethodExpression(ctx: context, method: method, on: on, values: tokens.last!.children.split(on: .whitespace).map { try resolveExpression(tokens: $0, infer: nil) })
        }
        
        // binary operators (by precedence)
        if let exp = try findBinary(within: ["&&", "||"], in: tokens)
                      ?? findBinary(within: [">=", "<=", ">", "<", "≥", "≤"], in: tokens)
                      ?? findBinary(within: ["&", "|", "^", "<<", ">>", ">>>"], in: tokens)
                      ?? findBinary(within: ["==", "!=", "≠"], in: tokens)
                      ?? findBinary(within: ["+", "-"], in: tokens)
                      ?? findBinary(within: ["*", "/", "%"], in: tokens) {
            return exp
        }
        
        // unary operators
        do {
            let op = tokens.first!
            if op.tokenType == .operator {
                switch op.literal {
                case "~", "-", "!":
                    return try UnaryExpression(context: context, op: String(op.literal), exp: try resolveExpression(tokens: Array(tokens.dropFirst()), infer: infer))
                default:
                    break
                }
            }
        }
        if tokens.last?.literal == "!" {
            return try UnboxExpression(exp: resolveExpression(tokens: Array(tokens.dropLast()), infer: infer?.optional))
        }
        
        // exp.methodName[...]
        if TokenMatcher(types: .dot, .identifier, .squareBrackets).matches(tokens: tokens.suffix(3)) {
            let on = try resolveExpression(tokens: tokens.dropLast(3), infer: nil)
            let name = tokens[tokens.count - 2]
            guard let method = Method(imports: context.imports, namespace: NameSpaces.none, name: String(name.literal), inType: try on.getType(context: context, infer: SimpleType.mixed)) else {
                throw GRPHCompileError(type: .undeclared, message: "Undeclared method '\(try on.getType(context: context, infer: SimpleType.mixed)).\(name.literal)'")
            }
            resolveSemanticToken(name.withType(.method).withModifiers([.defaultLibrary, .call], data: .method(method)))
            return try MethodExpression(ctx: context, method: method, on: on, values: tokens.last!.children.split(on: .whitespace).map { try resolveExpression(tokens: $0, infer: nil) })
        }
        
        if TokenMatcher(types: .dot, .identifier).matches(tokens: tokens.suffix(2)) {
            let on = tokens[0..<(tokens.count - 2)]
            let field = tokens.last!
            if field.literal.first!.isUppercase {
                // constant property
                let typeLiteral: Token
                if on.count == 1 && on[0].tokenType == .squareBrackets {
                    typeLiteral = Token(compound: on[0].children, type: .type)
                } else {
                    typeLiteral = Token(compound: Array(on), type: .type)
                }
                resolveSemanticToken(typeLiteral.withModifiers([]))
                guard let type = GRPHTypes.parse(context: context, literal: String(typeLiteral.literal)) else {
                    throw DiagnosticCompileError(notice: Notice(token: typeLiteral, severity: .error, source: .generator, message: "Could not resolve type literal"))
                }
                if field.literal == "TYPE" {
                    resolveSemanticToken(field.withType(.keyword).withModifiers([]))
                    return TypeValueExpression(type: type)
                } else if let const = type.staticConstants.first(where: { $0.name == field.literal }) {
                    resolveSemanticToken(field.withType(.property).withModifiers(.readonly, data: .property(const, in: type)))
                    return ConstantPropertyExpression(property: const, inType: type)
                } else {
                    throw DiagnosticCompileError(notice: Notice(token: field, severity: .error, source: .generator, message: "Could not find property '\(field.literal)' in type \(type)"))
                }
            } else {
                let exp = try resolveExpression(tokens: Array(on), infer: nil)
                if field.literal == "type" {
                    resolveSemanticToken(field.withType(.keyword).withModifiers([]))
                    return ValueTypeExpression(on: exp)
                }
                let type = try exp.getType(context: context, infer: SimpleType.mixed)
                if let property = GRPHTypes.field(named: String(field.literal), in: type) {
                    resolveSemanticToken(field.withType(.property).withModifiers(property.writeable ? .none : .readonly, data: .property(property, in: type)))
                    return FieldExpression(on: exp, field: property)
                } else {
                    throw DiagnosticCompileError(notice: Notice(token: field, severity: .error, source: .generator, message: "Could not find field '\(field.literal)' in type \(type)"))
                }
            }
        }
        
        throw DiagnosticCompileError(notice: Notice(token: Token(compound: tokens, type: .squareBrackets), severity: .error, source: .generator, message: "Could not resolve expression"))
    }
    
    func findBinary(within ops: [String], in tokens: [Token]) throws -> BinaryExpression? {
        try findBinary(within: ops, in: tokens) { lhs, op, rhs in
            return try BinaryExpression(
                context: context,
                left: resolveExpression(tokens: Array(lhs), infer: nil),
                op: String(op.literal),
                right: resolveExpression(tokens: Array(rhs), infer: nil)
            )
        }
    }
    
    func findCast(in tokens: [Token], infer: GRPHType?) throws -> CastExpression? {
        try findBinary(within: ["is", "as", "as?", "as!", "as?!"], in: tokens) { lhs, op, rhs in
            let compound = Token(compound: Array(rhs), type: .type)
            let casting: GRPHType
            if compound.literal == "auto" {
                if let infer = infer {
                    casting = infer
                } else {
                    throw DiagnosticCompileError(notice: Notice(token: compound, severity: .error, source: .generator, message: "Could not infer cast type automatically"))
                }
            } else if let type = GRPHTypes.parse(context: context, literal: String(compound.literal)) {
                resolveSemanticToken(compound.withModifiers([]))
                casting = type
            } else if compound.validTypeIdentifier {
                // we aren't sure if its valid or an error yet. add it as a hint
                diagnostics.append(Notice(token: compound, severity: .hint, source: .generator, message: "Couldn't parse '\(compound.literal)' as a type for cast expression"))
                return nil // maybe invalid
            } else {
                return nil // invalid
            }
            return try CastExpression(from: resolveExpression(tokens: Array(lhs), infer: casting), cast: CastType(String(op.literal))!, to: casting)
        }
    }
    
    func findBinary<T: Expression>(within ops: [String], in tokens: [Token], resolver: (ArraySlice<Token>, Token, ArraySlice<Token>) throws -> T?) rethrows -> T? {
        for (index, token) in tokens.enumerated().reversed() {
            if ops.contains(where: { $0 == token.literal }) {
                let lhs = tokens[..<index]
                let rhs = tokens[(index + 1)...]
                if !lhs.isEmpty && !rhs.isEmpty,
                   let result = try resolver(lhs, token, rhs) {
                    return result
                }
            }
        }
        return nil
    }
    
    func inferParametrableContent(_ p: Parametrable?) -> GRPHType? {
        if let params = p?.parameters,
           params.count == 1,
           let param = params.first {
            return param.type
        } else {
            return nil
        }
    }
    
    public func trimUselessStuff(children: [Token]) -> [Token] {
        var slice = children[...]
        
        while shouldTrim(type: slice.first?.tokenType) {
            slice = slice.dropFirst()
        }
        while shouldTrim(type: slice.last?.tokenType) {
            slice = slice.dropLast()
        }
        
        return Array(slice)
    }
    
    func shouldTrim(type: TokenType?) -> Bool {
        guard let type = type else {
            return false
        }
        return type == .indent || type == .whitespace || type == .comment || type == .docComment
    }
    
    func closeBlocks(tabs: Int) {
        let amount = blockCount - tabs
        guard amount != 0 else {
            return
        }
        guard amount > 0 else {
            diagnostics.append(Notice(token: lines[lineNumber].children[0], severity: .warning, source: .generator, message: "Unexpected indent, \(blockCount) indents or less were expected, but \(tabs) were found", hint: "You can use `#compiler indent n*spaces` to change the amount of indentation to use"))
            return
        }
        for _ in 0..<amount {
            if let swi = currentBlock as? SwitchTransparentBlock {
                blockCount -= 1
                if blockCount > 0 {
                    currentBlock!.children.removeLast() // remove the switch
                    currentBlock!.children.append(contentsOf: swi.children) // add its content
                } else {
                    instructions.removeLast()
                    instructions.append(contentsOf: swi.children)
                }
                context = (context as! SwitchCompilingContext).parent
            } else {
                blockCount -= 1
                context = (context as! BlockCompilingContext).parent
            }
        }
    }
    
    func addBlock(_ instruction: BlockInstruction) throws {
        var block = instruction
        block.label = nextLabel?.description
        nextLabel = nil
        try addInstruction(block)
        blockCount += 1
    }
    
    func addInstruction(_ instruction: Instruction) throws {
        try context.accepts(instruction: instruction)
        if blockCount == 0 {
            instructions.append(instruction)
        } else {
            currentBlock!.children.append(instruction)
        }
    }
    
    public func dumpWDIU() {
        print("[WDIU START]")
        var builder = ""
        for line in instructions {
            builder += line.toString(indent: "\t")
        }
        print(builder, terminator: "")
        print("[WDIU END]")
    }
    
    // Those come from GRPHCompiler — ugly & dirty
    
    private func findTryBlock(minus: Int = 1) throws -> Int {
        var last: Instruction? = nil
        if blockCount > 0,
           let block = currentBlock {
            if block.children.count >= minus {
                last = block.children[block.children.count - minus]
            }
        } else {
            if instructions.count >= minus {
                last = instructions[instructions.count - minus]
            }
        }
        if last is TryBlock {
            return minus
        } else if last is CatchBlock {
            return try findTryBlock(minus: minus + 1)
        }
        throw GRPHCompileError(type: .parse, message: "#catch requires a #try block before")
    }
    
    private var currentBlock: BlockInstruction? {
        get {
            lastBlock(in: instructions, max: blockCount)
        }
        set {
            let succeeded = lastBlock(in: &instructions, max: blockCount, new: newValue!)
            assert(succeeded)
        }
    }
    
    private func lastBlock(in arr: [Instruction], max: Int) -> BlockInstruction? {
        if max == 0 {
            return nil
        } else if let curr = arr.last as? BlockInstruction {
            if max == 1 {
                return curr
            }
            return lastBlock(in: curr.children, max: max - 1) ?? curr
        } else {
            return nil
        }
    }
    
    private func lastBlock(in arr: inout [Instruction], max: Int, new: BlockInstruction) -> Bool {
        if max == 1 {
            arr[arr.count - 1] = new
            return true
        }
        if var copy = arr.last as? BlockInstruction {
            if lastBlock(in: &copy.children, max: max - 1, new: new) {
                arr[arr.count - 1] = copy
                return true
            } else {
                arr = new.children
                return true
            }
        } else {
            return false
        }
    }
    
    struct ResolvedInstruction {
        var instruction: Instruction
        // only true for inline function definitions
        var notABlock = false
    }
}

public struct DiagnosticCompileError: Error {
    public var notice: Notice
}

extension CompilingContext {
    var generator: GRPHGenerator {
        compiler as! GRPHGenerator
    }
}
