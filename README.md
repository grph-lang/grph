# The GRPH Programming Language

The GRPH programming language is designed for animating shapes in a procedural way.

The first implementation was in Java, then it has been ported to Swift, and has finally been refactored in a modular way, with a brand new multiple-phase compiler (but still using the same runtime).

To see the shapes animate, check out [the app](https://github.com/Snowy1803/Graphism-Swift), which adds SwiftUI bindings to the runtime, to make an iOS + macOS app out of it.

The CLI has been tested and works on macOS, Linux and Windows, and depends on Swift.  
The LSP server works on macOS and Linux. The LSP Bindings for Swift, sourcekit-lsp, doesn't currently support Windows.

## Modules
- GRPHLexer: First phase of the compiler, transforms source code to an AST
- GRPHGenerator: Second phase of the compiler, transforms the AST to Instructions
- GRPHValues: Common types used in GRPH: contains instructions, expressions, namespaces, functions, methods, types, properties, variables, value types, shapes, etc.
- GRPHRuntime: The runtime, implementing the standard library in Swift, and an interpreted runtime
- DocGen: The documentation generator, linking symbols to their doc comments. Also parses doc comment keywords and emits deprecation & invalid doc comment warnings
- CLI: The command line compiler and runner. It wraps the other modules into a simple command line tool to run programs headlessly.
- LSP: The language server for GRPH, compatible with all IDEs implementing LSP (VSCode, vim, eclipse, etc). It provides semantic highlighting, documentation on hover, jump to definition, document highlight, outlines, and color preview.
- IRGen: (soon) New optional phase of the compiler, transforms Instructions into LLVM IR, to replace the interpreted runtime, and use a native standard library.

## Sample projects

You can check out [the samples](https://github.com/Snowy1803/Graphism-Projects) made for Graphism Java. Some will work, some won't.
