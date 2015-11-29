## Generate compile_commands.json for premake projects

This module implements [JSON Compilation Database Format
Specification](http://clang.llvm.org/docs/JSONCompilationDatabase.html) for
premake projects.

Install this module somewhere premake can find it, for example:

```
git clone https://github.com/tarruda/premake-export-compile-commands export-compile-commands
```

Then put this at the top of your system script(eg: ~/.premake/premake-system.lua):

```lua
require "export-compile-commands"
```

Note that while possible, it is not recommended to put the `require` line in
project-specific premake configuration because the "export-compile-commands"
module will need to be installed everywhere your project is built.

After the above steps, the "export-compile-commands" action will be available
for your projects:

```
premake5 export-compile-commands --config=Debug --platform=x86
```

By default, the above command creates a `compile_commands.json` file near your
other generated project files, but you can override with the --output-file
option:

```
premake5 export-compile-commands --output-file=release_compile_commands.json --config=Release
```
