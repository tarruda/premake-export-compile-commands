## Generate compile_commands.json for premake projects

This module implements [JSON Compilation Database Format
Specification](http://clang.llvm.org/docs/JSONCompilationDatabase.html) for
premake projects.

Install this module somewhere premake can find it, for example:

```
git clone https://github.com/tarruda/premake-export-compile-commands export-compile-commands
```

Then put this at the top of your project file:

```lua
require "export-compile-commands"
```

This will make the "export-compile-commands" action available for your project:

```
premake5 export-compile-commands --config=Debug --platform=x86
```
