//
//  GRPHRuntime.swift
//  Graphism
//
//  Created by Emil Pedersen on 06/07/2020.
//

import Foundation
import GRPHValues

typealias Method = GRPHValues.Method

public class GRPHRuntime {
    
    // Debugging
    public var debugging: Bool = false {
        didSet {
            if debugging && context != nil {
                for v in context.allVariables {
                    printout("[DEBUG VAR \(v.name)=\(v.content ?? "<@#invalid#@>")]")
                }
            }
        }
    }
    public var debugStep: TimeInterval = 0
    public var debugSemaphore = DispatchSemaphore(value: 0)
    
    var initialGlobalVariables: [Variable]
    var instructions: [Instruction]
    var timestamp: Date!
    public var context: RuntimeContext!
    
    public var localFunctions: [Function] = []
    
    public var image: GImage
    
    var settings: [RuntimeSetting: Bool] = [:]
    
    public init(instructions: [Instruction], globalVariables: [Variable], image: GImage) {
        self.instructions = instructions
        self.initialGlobalVariables = globalVariables
        self.image = image
        self.initialGlobalVariables.append(Variable(name: "back", type: SimpleType.Background, content: image, final: false))
    }
    
//    convenience init(compiler: GRPHCompiler, image: GImage) {
//        self.init(instructions: compiler.instructions, globalVariables: TopLevelCompilingContext.defaultVariables.filter { !$0.compileTime } + compiler.internStrings.enumerated().map({ i, s in Variable(name: "$_str\(i)$", type: SimpleType.string, content: s, final: true)}), image: image)
//        self.settings = compiler.settings
//        self.localFunctions = compiler.imports.compactMap { $0 as? Function }.filter { $0.ns.isEqual(to: NameSpaces.none) }
//    }
    
    public func run() -> Bool {
        timestamp = Date()
        context = TopLevelRuntimeContext(runtime: self)
        do {
            var last: RuntimeContext?
            var i = 0
            while i < instructions.count && !Thread.current.isCancelled {
                guard let line = instructions[i] as? RunnableInstruction else {
                    throw GRPHRuntimeError(type: .unexpected, message: "Instruction of type \(type(of: instructions[i])) (line \(instructions[i].line)) has no runnable implementation")
                }
                context.previous = last
                if debugging {
                    printout("[DEBUG LOC \(line.line)]")
                }
                if image.destroyed {
                    throw GRPHExecutionTerminated()
                }
                if debugStep > 0 {
                    _ = debugSemaphore.wait(timeout: .now() + debugStep)
                }
                var inner = context!
                try line.safeRun(context: &inner)
                if inner !== context! {
                    last = inner
                } else {
                    last = nil
                }
                i += 1
            }
            image.destroy()
            context = nil // break circular reference
            return true
        } catch let e as GRPHRuntimeError {
            printerr("GRPH exited because of an unhandled exception")
            printerr("\(e.type.rawValue)Exception: \(e.message)")
            e.stack.forEach { printerr($0) }
        } catch is GRPHExecutionTerminated {
            context = nil // break circular reference
            return true // Returning normally, execution terminated from an "end:" instruction or by the user when closing the file
        } catch let e {
            printerr("GRPH exited because of an unknown native error")
            printerr("\(e)")
        }
        image.destroy()
        context = nil // break circular reference
        return false
    }
    
    func triggerAutorepaint() {
        if settings[current: .autoupdate] {
            image.willNeedRepaint()
        }
    }
    
    var imports: [Importable] {
        NameSpaces.instances + localFunctions
    }
}

func printout(_ str: String, terminator: String = "\n") {
//    guard let data = (str + terminator).data(using: .utf8) else { return }
//    FileHandle.standardOutput.write(data)
    print(str, terminator: terminator)
}

func printerr(_ str: String, terminator: String = "\n") {
    guard let data = (str + terminator).data(using: .utf8) else { return }
    FileHandle.standardError.write(data)
}

struct GRPHExecutionTerminated: Error {
    
}

enum RuntimeSetting: String {
    case autoupdate, selection, generated, sidebar, propertybar, toolbar, movable, editable
    
    var defaultValue: Bool {
        switch self {
        case .autoupdate, .selection, .sidebar, .propertybar, .toolbar, .movable, .editable:
            return true
        case .generated:
            return false // flag "generated automatically; you can save the state over the file with no loss"
        }
    }
}

extension Dictionary where Key == RuntimeSetting, Value == Bool {
    subscript(current setting: RuntimeSetting) -> Value {
        return self[setting] ?? setting.defaultValue
    }
}
