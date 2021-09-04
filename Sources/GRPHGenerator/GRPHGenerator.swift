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
            } catch is GRPHHandledCompileError {
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
                diagnostics.append(Notice(token: line, severity: .error, source: .generator, message: "An internal error occured while parsing this line: \(type(of: error))"))
                diagnostics.append(Notice(token: line, severity: .hint, source: .generator, message: error.localizedDescription))
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
                    diagnostics.append(Notice(token: cmd, severity: .error, source: .generator, message: "A command name can't be empty"))
                    diagnostics.append(Notice(token: cmd, severity: .hint, source: .generator, message: "Did you mean to comment this line? Use '//'"))
                    throw GRPHHandledCompileError()
                }
            case "#import", "#using":
                let ns: NameSpace
                let member: Token
                if tokens.count == 4 || tokens.count >= 6 { // #import ns>member || #import ns>type.method
                    guard tokens[2].literal == ">" else {
                        diagnostics.append(Notice(token: tokens[2], severity: .error, source: .generator, message: "Expected `>` in namespaced member"))
                        throw GRPHHandledCompileError()
                    }
                    guard let namespace = NameSpaces.namespace(named: String(tokens[1].literal)) else {
                        diagnostics.append(Notice(token: tokens[2], severity: .error, source: .generator, message: "Namespace `\(tokens[1].literal)` was not found"))
                        throw GRPHHandledCompileError()
                    }
                    ns = namespace
                    if tokens.count == 4 {
                        member = tokens[3]
                    } else { // method import
                        guard tokens[tokens.count - 2].tokenType == .dot else {
                            diagnostics.append(Notice(token: tokens[tokens.count - 2], severity: .error, source: .generator, message: "Expected a dot in `#import namespaceName>typeIdentifier.methodName` syntax"))
                            throw GRPHHandledCompileError()
                        }
                        let literalType = tokens[3].literal.base[(tokens[3].lineOffset)..<(tokens[tokens.count - 3].literal.endIndex)]
                        guard let type = GRPHTypes.parse(context: context, literal: String(literalType)) else {
                            diagnostics.append(Notice(token: Token(lineNumber: tokens[3].lineNumber, lineOffset: literalType.startIndex, literal: literalType, tokenType: .type), severity: .error, source: .generator, message: "Could not parse type `\(literalType)`"))
                            throw GRPHHandledCompileError()
                        }
                        guard let m = Method(imports: [], namespace: ns, name: String(tokens[tokens.count - 2].literal), inType: type) else {
                            diagnostics.append(Notice(token: tokens[tokens.count - 2], severity: .error, source: .generator, message: "Could not find method '\(tokens[tokens.count - 2].literal)' in type '\(type)'"))
                            throw GRPHHandledCompileError()
                        }
                        imports.append(m)
                        return nil
                    }
                } else if tokens.count == 2 { // #import member
                    ns = NameSpaces.none
                    member = tokens[1]
                } else {
                    diagnostics.append(Notice(token: cmd, severity: .error, source: .generator, message: "`#import` needs an argument: What namespace do you want to import?"))
                    throw GRPHHandledCompileError()
                }
                let memberLiteral = String(member.literal)
                if ns.isEqual(to: NameSpaces.none) {
                    if let ns = NameSpaces.namespace(named: memberLiteral) {
                        imports.append(ns)
                    } else {
                        diagnostics.append(Notice(token: member, severity: .error, source: .generator, message: "Namespace `\(memberLiteral)` was not found"))
                        throw GRPHHandledCompileError()
                    }
                } else if let f = Function(imports: [], namespace: ns, name: memberLiteral) {
                    imports.append(f)
                } else if let t = ns.exportedTypes.first(where: { $0.string == memberLiteral }) {
                    imports.append(t)
                } else if let t = ns.exportedTypeAliases.first(where: { $0.name == memberLiteral }) {
                    imports.append(t)
                } else {
                    diagnostics.append(Notice(token: member, severity: .error, source: .generator, message: "Could not find member '\(memberLiteral)' in namespace '\(ns.name)'"))
                    throw GRPHHandledCompileError()
                }
                return nil
            case "#typealias":
                guard tokens.count >= 3 else {
                    diagnostics.append(Notice(token: cmd, severity: .error, source: .generator, message: "`#typealias` needs two arguments: #typealias newname existingType"))
                    throw GRPHHandledCompileError()
                }
                let literalType = tokens[2].literal.base[(tokens[2].lineOffset)..<(tokens[tokens.count - 1].literal.endIndex)]
                guard let type = GRPHTypes.parse(context: context, literal: String(literalType)) else {
                    diagnostics.append(Notice(token: Token(lineNumber: tokens[2].lineNumber, lineOffset: literalType.startIndex, literal: literalType, tokenType: .type), severity: .error, source: .generator, message: "Could not find type `\(literalType)`"))
                    throw GRPHHandledCompileError()
                }
                let newname = String(tokens[1].literal)
                guard GRPHTypes.parse(context: context, literal: newname) == nil else {
                    diagnostics.append(Notice(token: tokens[1], severity: .error, source: .generator, message: "Cannot override existing type `\(newname)` with a typealias"))
                    throw GRPHHandledCompileError()
                }
                switch newname {
                case "file", "image", "Image", "auto",
                     "final", "global", "static", "public", "private", "protected",
                     "dict", "set", "tuple":
                    diagnostics.append(Notice(token: tokens[1], severity: .error, source: .generator, message: "Type name '\(newname)' is reserved and can't be used as a typealias name"))
                    throw GRPHHandledCompileError()
                case VariableDeclarationInstruction.varNameRequirement:
                    break
                default:
                    diagnostics.append(Notice(token: tokens[1], severity: .error, source: .generator, message: "Type name '\(newname)' is not a valid type name"))
                    throw GRPHHandledCompileError()
                }
                if newname.hasSuffix("Error") || newname.hasSuffix("Exception") {
                    diagnostics.append(Notice(token: tokens[1], severity: .error, source: .generator, message: "Type name '\(newname)' is reserved and can't be used as a typealias name"))
                    throw GRPHHandledCompileError()
                }
                imports.append(TypeAlias(name: newname, type: type))
                return nil
            default:
                diagnostics.append(Notice(token: cmd, severity: .error, source: .generator, message: "Unknown command '\(cmd.literal)'"))
                throw GRPHHandledCompileError()
            }
        }
        
        
        throw GRPHCompileError(type: .unsupported, message: "compiler ain't ready")
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
            diagnostics.append(Notice(token: lines[lineNumber].children[0], severity: .warning, source: .generator, message: "Unexpected indent, \(blockCount) indents or less were expected, but \(tabs) were found"))
            diagnostics.append(Notice(token: lines[lineNumber].children[0], severity: .hint, source: .generator, message: "You can use `#compiler indent n*spaces` to change the amount of indentation to use"))
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

struct GRPHHandledCompileError: Error {
    
}
