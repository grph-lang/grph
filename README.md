# The GRPH Programming Language

The GRPH programming language is designed for animating shapes in a procedural way.

The first implementation was in Java, then it has been ported to Swift, and has finally been refactored in a modular way, with a brand new multiple-phase compiler.

To see the shapes animate, check out [the app](https://github.com/Snowy1803/Graphism-Swift), which adds SwiftUI bindings to the runtime, to make an iOS + macOS app out of it.

The CLI and LSP server have both been tested and they work on macOS, Linux and Windows.  
The compiler depends on [Swift](https://www.swift.org/getting-started/) and [LLVMSwift](https://github.com/llvm-swift/LLVMSwift#installation).

## Modules
- GRPHLexer: First phase of the compiler, transforms source code into a concrete syntax tree (lexed tokens)
- GRPHGenerator: Second phase of the compiler, transforms the CST into an AST (Instructions & Expressions)
- GRPHValues: Common types used in GRPH: contains instructions, expressions, namespaces, functions, methods, types, properties, variables, value types, shapes, etc.
- GRPHRuntime: The runtime, implementing the standard library in Swift, and an interpreted runtime
- DocGen: The documentation generator, linking symbols to their doc comments. Also parses doc comment keywords and emits deprecation & invalid doc comment warnings
- CLI: The command line compiler and runner. It wraps the other modules into a simple command line tool to run programs headlessly.
- LSP: The language server for GRPH, compatible with all IDEs implementing LSP ([VSCode](https://github.com/grph-lang/grph-vscode), [emacs](https://github.com/grph-lang/grph-mode), etc). It provides semantic highlighting, documentation on hover, jump to definition, document highlight, outlines, and color preview.
- IRGen: (wip) New optional phase of the compiler, transforms Instructions into LLVM IR, to replace the interpreted runtime. It uses [a native standard library](https://github.com/grph-lang/grph-stdlib) (which must be installed too).

## Sample projects

You can check out [the samples](https://github.com/Snowy1803/Graphism-Projects) made for Graphism Java. Some will work, some won't.
