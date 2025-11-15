# Nim Compiler Improvement Suggestions
## Developer Understanding and Debugging Enhancements

### 1. Enhanced Type Mismatch Messages ⭐⭐⭐⭐⭐

**Current:**
```
Error: type mismatch: got <int, string> but expected one of:
proc add(x, y: int): int
```

**Suggested:**
```
Error:[E0234]: type mismatch in call to 'add'
 --> file.nim(10, 5)
    |
 10 |   add(42, "hello")
    |       ^^  ^^^^^^^ expected 'int', found 'string'
    |       |
    |       this argument is correct
    |
note: candidate function signature
 --> stdlib/system.nim(150, 6)
    |
150 | proc add(x, y: int): int
    |      ^^^ ------  --- required type
    |
help: convert the string to int
    | add(42, parseInt("hello"))
```

**Implementation:**
- Track each argument's type in overload resolution
- Show inline type annotations at call sites
- Suggest type conversions when available
- Show all candidates with reasons for rejection

---

### 2. Improved Macro/Template Expansion Debugging ⭐⭐⭐⭐⭐

**Current:**
```
Error: undeclared identifier: 'foo'
```
(No indication it came from a macro expansion)

**Suggested:**
```
Error:[E0017]: undeclared identifier: 'foo'
 --> file.nim(25, 10)
    |
 25 |   myMacro(bar)
    |   ^^^^^^^^^^^ in this macro expansion
    |
note: expanded to
    |
    | foo.doSomething()
    | ^^^ not found in this scope
    |
note: macro defined here
 --> macros.nim(10, 8)
    |
help: the macro expanded to use 'foo', but it's not in scope
```

**Features:**
- `--expandMacros:<name>` - Show expansion of specific macro
- `--traceExpansions` - Show full expansion chain
- `--showGeneratedCode:<line>` - Show what code was generated at a line
- Syntax highlighting in expanded code display
- Expansion depth indicator to prevent confusion

---

### 3. Better Overload Resolution Error Messages ⭐⭐⭐⭐⭐

**Current:**
```
Error: type mismatch: got <MyType>
but expected one of:
proc foo(x: int): void
proc foo(x: string): void
proc foo[T](x: seq[T]): void
```

**Suggested:**
```
Error:[E0567]: no matching overload for 'foo(MyType)'
 --> file.nim(30, 3)
    |
 30 |   foo(myValue)
    |   ^^^ ------- has type 'MyType'
    |
note: candidate 1 of 3
 --> module.nim(10, 6)
    |
 10 | proc foo(x: int): void
    |      ^^^ -----
    |
    = note: expected 'int', found 'MyType' (no implicit conversion available)

note: candidate 2 of 3
 --> module.nim(15, 6)
    |
 15 | proc foo(x: string): void
    |      ^^^ ---------
    |
    = note: expected 'string', found 'MyType'

note: candidate 3 of 3
 --> module.nim(20, 6)
    |
 20 | proc foo[T](x: seq[T]): void
    |      ^^^ ------------
    |
    = note: expected 'seq[?T]', found 'MyType' (not a sequence type)

help: did you mean to convert 'myValue'?
    | foo($myValue)  # convert to string
```

**Implementation:**
- Show why each overload failed with specific type info
- Order candidates by "closeness" to the provided types
- Suggest available conversions
- Show generic type inference failures clearly

---

### 4. Symbol Provenance Tracking ⭐⭐⭐⭐

**Feature:** Show where symbols came from

```nim
# When using ambiguous imports
import module1, module2  # both export 'getValue'

getValue()  # Which one is being used?
```

**Suggested Error/Hint:**
```
Hint:[H0234]: using 'getValue' from 'module1'
 --> file.nim(5, 1)
    |
  5 | getValue()
    | ^^^^^^^^ imported from 'module1' at file.nim(1, 8)
    |
note: 'getValue' is also available from:
    - module2 (imported at file.nim(1, 17))
    |
help: use qualified access to be explicit
    | module1.getValue()  # or
    | module2.getValue()
```

**Additional Features:**
- `--showImports` - List all imported symbols and their sources
- `--explainSymbol:<name>` - Show full provenance of a symbol
- Warn on shadowing with different suggestions

---

### 5. Compile-Time Performance Profiling ⭐⭐⭐⭐

**Feature:** `--profileCompilation`

```
Compilation Profile Report
==========================

Phase                          Time      %    Memory
-------------------------------------------------
Parsing                       0.45s    5%     12MB
Semantic Analysis             4.32s   48%    156MB
  - Type inference            2.10s   23%     89MB
  - Overload resolution       1.89s   21%     45MB
  - Macro expansion           0.33s    4%     22MB
Template Instantiation        2.15s   24%     78MB
  - template myBigTemplate    1.98s   22%     67MB  ⚠ HOT
Code Generation               1.89s   21%     45MB
Optimization                  0.18s    2%      8MB
-------------------------------------------------
Total                         8.99s  100%    299MB

⚠ Compilation hotspots:
  1. template myBigTemplate (file.nim:45) - instantiated 1,247 times
  2. proc foo[T] (module.nim:123) - instantiated 89 times
  3. macro debug (macros.nim:67) - expanded 456 times

💡 Suggestions:
  - Consider reducing template 'myBigTemplate' complexity
  - Use 'mixin' to reduce generic instantiations
```

**Implementation:**
- Track time spent in each compilation phase
- Track memory allocation per phase
- Identify "hot" templates/macros that slow compilation
- Show concrete suggestions for improvement

---

### 6. Better ARC/ORC Debugging ⭐⭐⭐⭐

**Feature:** `--showMemoryManagement`

```
Memory Management Report for proc 'process'
============================================

  5 | proc process(data: string): seq[int] =
    |                             ^^^^^^^^ heap allocated, requires destroy
  6 |   var items = newSeq[int]()
    |       ^^^^^ move to result, no copy needed ✓
  7 |   items.add(parseInt(data))
  8 |   return items
    |          ^^^^^ moved to caller, no copy ✓
    |
  = note: 0 copies, 1 allocation, 1 move
  = note: this proc is move-optimized ✓

Memory Management Report for proc 'leak'
=========================================

 15 | proc leak() =
 16 |   var data = newSeq[string]()
    |       ^^^^ heap allocated
 17 |   if condition:
 18 |     return  # ⚠ WARNING: 'data' not destroyed on this path
    |     ^^^^^^
    |
Warning:[W0456]: potential memory leak in 'leak'
 --> file.nim(18, 5)
    |
 18 |     return
    |     ^^^^^^ early return skips destructor
    |
note: 'data' allocated here
 --> file.nim(16, 7)
    |
help: ensure cleanup before return
    | `=destroy`(data)
    | return
```

**Features:**
- Show where allocations happen
- Track moves vs copies
- Warn about potential leaks
- Show destructor insertion points
- Visualize object lifetime

---

### 7. Async Stack Traces ⭐⭐⭐⭐

**Current async error:**
```
Error: unhandled exception: Connection refused [OSError]
```

**Suggested:**
```
Error:[E0789]: unhandled exception: Connection refused [OSError]

Async Stack Trace:
 --> asyncApp.nim(45, 8)
    |
 45 |   await client.connect(host, port)
    |         ^^^^^^^^^^^^^^^^^^^^^^^^^ OSError raised here
    |
async caller chain:
  at handleRequest() asyncApp.nim(40, 6)
     called from processRequests() asyncApp.nim(120, 14)
     called from main() asyncApp.nim(200, 3)

note: this is an async exception chain, not a regular stack trace

help: check if the server is running
    | try:
    |   await client.connect(host, port)
    | except OSError as e:
    |   echo "Connection failed: ", e.msg
```

**Implementation:**
- Track async call chain separately
- Show which async proc called which
- Distinguish async vs sync stack traces
- Show await points clearly

---

### 8. Interactive Error Explanation ⭐⭐⭐

**Feature:** `--explain=<error-code>`

```bash
$ nim --explain=E0234

Error E0234: Type Mismatch
==========================

This error occurs when you try to pass arguments of the wrong type
to a procedure, or when the compiler can't find a matching overload.

Common causes:
1. Passing wrong argument types
2. Missing type conversions
3. Ambiguous overloads
4. Missing imports

Examples:

  ✗ Wrong:
    proc add(x, y: int): int = x + y
    add(1, "2")  # Error: can't pass string as int

  ✓ Correct:
    add(1, 2)           # both ints
    add(1, parseInt("2"))  # convert string to int

See also:
  - Type system: https://nim-lang.org/docs/tut2.html#types
  - Overloading: https://nim-lang.org/docs/tut2.html#overloading

Related errors: E0235, E0567
```

---

### 9. Code Action Suggestions ⭐⭐⭐⭐

**Feature:** Auto-fix suggestions for common issues

```
Error:[E0017]: undeclared identifier: 'strutils'
 --> file.nim(10, 8)
    |
 10 |   if strutils.startsWith(s, "hello"):
    |      ^^^^^^^^ not found in this scope
    |
help: did you forget to import 'strutils'?
    |
    | [FIX 1] Add import at top of file:
    | + import strutils
    |
    | [FIX 2] Use qualified import:
    | + from strutils import startsWith
```

**Common auto-fixes:**
- Add missing imports
- Fix common typos
- Add type annotations
- Convert between types
- Fix indentation errors
- Add missing return statements

---

### 10. Dependency Visualization ⭐⭐⭐

**Feature:** `--showDependencies=<format>`

```bash
$ nim --showDependencies=tree myapp.nim

myapp.nim
├── std/strutils
│   ├── std/parseutils
│   └── std/unicode
├── std/os
│   ├── std/oserrors
│   └── std/times
└── mymodule.nim
    ├── std/json
    │   ├── std/lexbase
    │   └── std/streams
    └── helpers.nim

Compilation order:
  1. std/parseutils
  2. std/unicode
  3. std/strutils
  4. std/oserrors
  5. std/times
  ...

Circular dependency check: ✓ None found
Total modules: 23
```

**Formats:**
- `tree` - Tree view (shown above)
- `dot` - GraphViz DOT format
- `json` - JSON for tooling
- `cycles` - Show only circular dependencies

---

### 11. Better Hint/Warning Control ⭐⭐⭐⭐

**Current:** Binary on/off for each hint

**Suggested:** Warning levels like GCC/Clang

```nim
# In nim.cfg or command line
--warningLevel:pedantic  # Show all warnings
--warningLevel:standard  # Normal warnings (default)
--warningLevel:minimal   # Only important warnings

# Or granular control
--warn:UnusedImport:error    # Treat as error
--warn:XDeclaredButNotUsed:off  # Disable
--warn:AnyEnumConv:style     # Only in --styleCheck mode
```

**Categories:**
- `correctness` - Likely bugs
- `style` - Style issues
- `performance` - Performance hints
- `deprecation` - Deprecated features
- `experimental` - Experimental features

---

### 12. Inline Type Information ⭐⭐⭐

**Feature:** `--showTypes` or IDE integration

```nim
proc process(data: string): seq[int] =
  var items = newSeq[int]()  # items: seq[int]
  for line in data.splitLines():  # line: string
    if line.len > 0:  # line.len: int
      items.add(parseInt(line))  # parseInt: proc(string): int
  return items  # returns: seq[int]
```

**In errors:**
```
Error:[E0234]: type mismatch
 --> file.nim(15, 8)
    |
 15 |   result.add(value)
    |              ^^^^^
    |              |
    |              type: float (expected: int)
    |
note: 'result' has type 'seq[int]'
 --> file.nim(12, 26)
    |
 12 | proc process(): seq[int] =
    |                 ^^^^^^^^
```

---

### 13. Better VM Error Messages ⭐⭐⭐⭐

**Current:**
```
Error: VM does not support 'importc' procs
```

**Suggested:**
```
Error:[E0901]: cannot execute 'importc' proc at compile time
 --> file.nim(15, 8)
    |
 15 |   const result = computeValue()
    |                  ^^^^^^^^^^^^^^ compile-time execution attempted
    |
note: 'computeValue' calls 'externalFunc'
 --> file.nim(10, 6)
    |
 10 | proc externalFunc(): int {.importc.}
    |      ^^^^^^^^^^^^ this proc uses foreign function interface
    |
    = note: 'importc' procs cannot run at compile time

help: move the computation to runtime
    | let result = computeValue()  # use 'let' instead of 'const'
    |
    or
    |
    | proc computeValue(): int {.compileTime.} =
    |   # reimplement without 'importc' calls
```

---

### 14. Incremental Compilation Insights ⭐⭐⭐

**Feature:** `--explain-rebuild`

```
Recompilation Report
====================

Modified files:
  mymodule.nim (timestamp changed)

Affected modules (will recompile):
  ├── mymodule.nim (modified)
  ├── app.nim (imports mymodule)
  ├── tests.nim (imports mymodule)
  └── utils.nim (imports app)

Skipped (cached):
  ├── std/strutils ✓
  ├── std/os ✓
  └── helpers.nim ✓

Cache statistics:
  Cached: 156 modules
  Recompiling: 4 modules
  Savings: ~3.2s (80% faster)

💡 To maximize caching:
  - Keep module interfaces stable
  - Use forward declarations
  - Minimize cross-module dependencies
```

---

### 15. Dead Code Detection ⭐⭐⭐

**Feature:** `--findDeadCode`

```
Dead Code Report
================

Unused exports in 'mymodule.nim':

  45 | proc helperFunc*(): int =
     |      ^^^^^^^^^^ exported but never imported
     |
  suggestion: remove '*' or delete if unneeded

  67 | type OldType* = object
     |      ^^^^^^^ exported but never used
     |
  suggestion: mark as deprecated first:
     | type OldType* {.deprecated: "use NewType".} = object

Unreachable code:

 120 | if true:
 121 |   doSomething()
 122 | else:
 123 |   doOtherThing()  # ⚠ unreachable: condition is always true
     |   ^^^^^^^^^^^^^^^
```

---

## Priority Implementation Order

### Phase 1 (High Impact, Moderate Effort)
1. ✅ **Enhanced error codes** (Already implemented)
2. **Better type mismatch messages**
3. **Improved overload resolution errors**
4. **Code action suggestions**

### Phase 2 (High Impact, Higher Effort)
5. **Macro/template expansion debugging**
6. **Symbol provenance tracking**
7. **Async stack traces**
8. **Interactive error explanations**

### Phase 3 (Nice to Have)
9. **Compile-time profiling**
10. **ARC/ORC debugging**
11. **Dependency visualization**
12. **Dead code detection**

### Phase 4 (Tooling/IDE)
13. **Inline type information**
14. **Warning levels**
15. **Incremental compilation insights**

---

## Implementation Notes

### General Principles
- **Actionable errors**: Always suggest how to fix
- **Context preservation**: Show where things came from
- **Progressive disclosure**: Basic error + optional detail
- **Consistency**: Use same format across all errors
- **Performance**: Don't slow down compilation

### Technical Considerations
- Store more metadata during compilation (symbol origins, type inference chains)
- Enhance `TLineInfo` to track transformation history
- Add structured diagnostic builder API
- Create error explanation database
- Build IDE protocol for code actions

### Backward Compatibility
- All new features behind flags
- Keep legacy output format as default
- Add `--errorFormat=json` for tooling
- Maintain stable error codes
