# The GRPH Programming Language

The GRPH programming language is designed for animating shapes in a procedural way.

The first implementation was in Java, then it has been ported to Swift, and has finally been refactored in a modular way, with a brand new multiple-phase compiler (but still using the same runtime).

To see the shapes animate, for now, check out [the legacy project](https://github.com/Snowy1803/Graphism-Swift) (this swift package does not include the SwiftUI bindings yet)

## Modules
- GRPHLexer: First phase of the compiler, transforms source code to an AST
- GRPHGenerator: Second phase of the compiler, transforms the AST to Instructions
- GRPHValues: Common types used in GRPH: contains instructions, expressions, namespaces, functions, methods, types, properties, variables, value types, shapes, etc.
- GRPHRuntime: The runtime, implementing the standard library
- DocGen: The documentation generator, linking symbols and their doc comments. Also parses doc comment keywords and emits deprecation & invalid doc comment warnings
- CLI: The command line compiler and runner, headless (so no animations)
- LSP: The language server for GRPH, compatible with all IDEs implementing LSP (VSCode, vim, eclipse, etc). It provides semantic highlighting, documentation on hover, jump to definition, document highlight, outlines, and color preview.
- IRGen: (probably never) New optional phase of the compiler, transforms Instructions into LLVM IR

## Sample projects

You can check out the samples made for [Graphism Java](https://github.com/Snowy1803/Graphism-Projects). Some will work, some won't.
