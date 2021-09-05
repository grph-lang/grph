//
//  GRPHGenerator.swift
//  GRPHGenerator
//
//  Created by Emil Pedersen on 04/09/2021.
//

import GRPHLexer
import GRPHValues

class GRPHGenerator: GRPHCompilerProtocol {
    var imports: [Importable] = [NameSpaces.namespace(named: "standard")!]
    
    var hasStrictUnboxing: Bool = false
    var hasStrictBoxing: Bool = false
    
    var lines: [Token]
    
    var lineNumber = 0
    
    var blockCount = 0
    var instructions: [Instruction] = []
    
    var context: CompilingContext!
    
    public private(set) var diagnostics: [Notice] = []
    
    init(lines: [Token]) {
        self.lines = lines
    }
    
    func compile() -> Bool {
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
                try resolveInstruction(children: trimmed)
            } catch let error as DiagnosticCompileError {
                diagnostics.append(error.notice)
                context = nil
                return false
            } catch let error as GRPHCompileError {
//                if compilerSettings.contains(.ignoreErrors) || compilerSettings.contains(.ignore(error.type)) {
//                    continue
//                }
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
        return true
    }
    
    func resolveInstruction(children: [Token]) throws -> ResolvedInstruction? {
        // children is guaranteed to be non empty
        
        if children[0].tokenType == .commandName {
            let cmd = children[0]
            let tokens = children.stripped
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
                    ns = namespace
                    if tokens.count == 4 {
                        member = tokens[3]
                    } else { // method import
                        guard tokens[tokens.count - 2].tokenType == .dot else {
                            throw DiagnosticCompileError(notice: Notice(token: tokens[tokens.count - 2], severity: .error, source: .generator, message: "Expected a dot in `#import namespaceName>typeIdentifier.methodName` syntax"))
                        }
                        let typeToken = Token(compound: Array(tokens[3...(tokens.count - 3)]), type: .type)
                        guard let type = GRPHTypes.parse(context: context, literal: String(typeToken.literal)) else {
                            throw DiagnosticCompileError(notice: Notice(token: typeToken, severity: .error, source: .generator, message: "Could not parse type `\(typeToken.literal)`"))
                        }
                        guard let m = Method(imports: [], namespace: ns, name: String(tokens[tokens.count - 2].literal), inType: type) else {
                            throw DiagnosticCompileError(notice: Notice(token: tokens[tokens.count - 2], severity: .error, source: .generator, message: "Could not find method '\(tokens[tokens.count - 2].literal)' in type '\(type)'"))
                        }
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
                        imports.append(ns)
                    } else {
                        throw DiagnosticCompileError(notice: Notice(token: member, severity: .error, source: .generator, message: "Namespace `\(memberLiteral)` was not found"))
                    }
                } else if let f = Function(imports: [], namespace: ns, name: memberLiteral) {
                    imports.append(f)
                } else if let t = ns.exportedTypes.first(where: { $0.string == memberLiteral }) {
                    imports.append(t)
                } else if let t = ns.exportedTypeAliases.first(where: { $0.name == memberLiteral }) {
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
                let newname = String(tokens[1].literal)
                guard GRPHTypes.parse(context: context, literal: newname) == nil else {
                    throw DiagnosticCompileError(notice: Notice(token: tokens[1], severity: .error, source: .generator, message: "Cannot override existing type `\(newname)` with a typealias"))
                }
                switch newname {
                case "file", "image", "Image", "auto",
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
            default:
                throw DiagnosticCompileError(notice: Notice(token: cmd, severity: .error, source: .generator, message: "Unknown command '\(cmd.literal)'"))
            }
        }
        
        
        throw GRPHCompileError(type: .unsupported, message: "compiler ain't ready")
    }
    
    func resolveExpression(tokens _tokens: [Token], infer: GRPHType?) throws -> Expression {
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
                if case .float(let x) = token.children[0].data,
                   case .float(let y) = token.children[2].data {
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
                    return try ConstructorExpression(ctx: context, type: type, values: token.children.split(on: .ignoreableWhiteSpace).map { try resolveExpression(tokens: $0, infer: content)})
                } else {
                    throw DiagnosticCompileError(notice: Notice(token: token, severity: .error, source: .generator, message: "Constructor type could not be inferred"))
                }
            case .curlyBraces:
                diagnostics.append(Notice(token: token, severity: .warning, source: .generator, message: "Array literals are deprecated", hint: "Use constructors instead"))
                let wrapped: GRPHType
                if let infer = infer as? ArrayType {
                    wrapped = infer.content
                } else {
                    diagnostics.append(Notice(token: token, severity: .warning, source: .generator, message: "Array literal type couldn't be inferred, assuming floats"))
                    wrapped = SimpleType.float
                }
                return try ArrayLiteralExpression(wrapped: wrapped, values: token.children.split(on: .comma).map { tokens in
                    let exp = try GRPHTypes.autobox(context: context, expression: resolveExpression(tokens: tokens, infer: wrapped), expected: wrapped)
                    let type = try exp.getType(context: context, infer: wrapped)
                    guard type.isInstance(of: wrapped) else {
                        throw DiagnosticCompileError(notice: Notice(token: Token(compound: tokens, type: .squareBrackets), severity: .error, source: .generator, message: "Value of type '\(type)' couldn't be converted to \(wrapped)"))
                    }
                    return exp
                })
            case .identifier:
                // RESOLVE semantic token: variable
                return VariableExpression(name: String(token.literal))
            default:
                break
            }
        }
        switch tokens {
        case TokenMatcher(types: .lambdaHatOperator, .squareBrackets): // ^[...]
            return try LambdaExpression(context: context, token: tokens[1], infer: infer)
        case TokenMatcher(types: .lambdaHatOperator, .identifier): // ^funcName
            // RESOLVE semantic token: function
            let name = String(tokens[1].literal)
            guard let function = Function(imports: context.imports, namespace: NameSpaces.none, name: name) else {
                throw DiagnosticCompileError(notice: Notice(token: tokens[1], severity: .error, source: .generator, message: "Could not find function '\(name)'"))
            }
            return try FunctionReferenceExpression(function: function, infer: infer)
        case TokenMatcher(types: .identifier, .squareBrackets): // funcName[...]
            // RESOLVE semantic token: function
            let name = String(tokens[0].literal)
            guard let function = Function(imports: context.imports, namespace: NameSpaces.none, name: name) else {
                throw DiagnosticCompileError(notice: Notice(token: tokens[0], severity: .error, source: .generator, message: "Could not find function '\(name)'"))
            }
            return try FunctionExpression(ctx: context, function: function, values: tokens[1].children.split(on: .ignoreableWhiteSpace).map { try resolveExpression(tokens: $0, infer: nil) })
        case TokenMatcher(.type(.identifier), ">", .type(.identifier), .type(.squareBrackets)): // ns>funcName[...]
            // RESOLVE semantic token: namespace, function
            guard let ns = NameSpaces.namespace(named: String(tokens[0].literal)) else {
                throw DiagnosticCompileError(notice: Notice(token: tokens[0], severity: .error, source: .generator, message: "Could not find namespace '\(tokens[0].literal)'"))
            }
            let name = String(tokens[0].literal)
            guard let function = Function(imports: context.imports, namespace: ns, name: name) else {
                throw DiagnosticCompileError(notice: Notice(token: tokens[0], severity: .error, source: .generator, message: "Could not find function '\(name)' in namespace '\(ns.name)'"))
            }
            return try FunctionExpression(ctx: context, function: function, values: tokens[1].children.split(on: .ignoreableWhiteSpace).map { try resolveExpression(tokens: $0, infer: nil) })
        case TokenMatcher(types: .identifier, .curlyBraces): // varName{...}
            // RESOLVE semantic token: variable
            let removing = tokens[1].children.last?.literal == "-"
            let children = tokens[1].children.dropLast(removing ? 1 : 0)
            return try ArrayValueExpression(context: context, varName: String(tokens[0].literal), index: children.isEmpty ? nil : resolveExpression(tokens: Array(children), infer: SimpleType.integer), removing: removing)
        case TokenMatcher(types: .identifier, .lambdaHatOperator, .squareBrackets): // varName^[...]
            // RESOLVE semantic token: variable
            return try FuncRefCallExpression(ctx: context, varName: String(tokens[0].literal), values: tokens[2].children.split(on: .ignoreableWhiteSpace).map { try resolveExpression(tokens: $0, infer: nil) })
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
                    return try ConstructorExpression(ctx: context, type: type, values: tokens.last!.children.split(on: .ignoreableWhiteSpace).map { try resolveExpression(tokens: $0, infer: content)})
                } else {
                    throw DiagnosticCompileError(notice: Notice(token: compound, severity: .error, source: .generator, message: "Constructor type could not be inferred"))
                }
            } else if let type = GRPHTypes.parse(context: context, literal: String(compound.literal)) {
                let content = inferParametrableContent(type.constructor)
                return try ConstructorExpression(ctx: context, type: type, values: tokens.last!.children.split(on: .ignoreableWhiteSpace).map { try resolveExpression(tokens: $0, infer: content)})
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
            
            diagnostics.append(Notice(token: tokens.last!, severity: .warning, source: .generator, message: "Array literals are deprecated", hint: "Use constructors instead"))
            
            return try ArrayLiteralExpression(wrapped: wrapped, values: tokens.last!.children.split(on: .comma).map { tokens in
                let exp = try GRPHTypes.autobox(context: context, expression: resolveExpression(tokens: tokens, infer: wrapped), expected: wrapped)
                let type = try exp.getType(context: context, infer: wrapped)
                guard type.isInstance(of: wrapped) else {
                    throw DiagnosticCompileError(notice: Notice(token: Token(compound: tokens, type: .squareBrackets), severity: .error, source: .generator, message: "Value of type '\(type)' couldn't be converted to \(wrapped)"))
                }
                return exp
            })
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
        
        // exp.method[...]
        // exp.ns>method[...]
        // exp.fieldName
        // type.FIELD_NAME, [type].FIELD_NAME
        
        // tests:
        // funcref<string><string+string>("static")
        // pos(4 1) + pos(1 2)
        // 1 + 2 as int == [1 + 2] as integer
        // -maybeInt! == -[maybeInt!]
        
        throw GRPHCompileError(type: .unsupported, message: "compiler ain't ready")
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
    
    func trimUselessStuff(children: [Token]) -> [Token] {
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
        return type == .indent || type == .ignoreableWhiteSpace || type == .comment || type == .docComment
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
    
    // Those come from GRPHCompiler — ugly & dirty
    
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

struct DiagnosticCompileError: Error {
    var notice: Notice
}

extension CompilingContext {
    var generator: GRPHGenerator {
        compiler as! GRPHGenerator
    }
}
