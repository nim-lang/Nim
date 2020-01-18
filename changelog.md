# 1.2 - xxxx-xx-xx


## Changes affecting backwards compatibility



### Breaking changes in the standard library

- `base64.encode` no longer supports `lineLen` and `newLine`.
  Use `base64.encodeMIME` instead.
- `os.splitPath()` behavior synchronized with `os.splitFile()` to return "/"
   as the dir component of "/root_sub_dir" instead of the empty string.
- `sequtils.zip` now returns a sequence of anonymous tuples i.e. those tuples
  now do not have fields named "a" and "b".
- `strutils.formatFloat` with `precision = 0` has the same behavior in all
  backends, and it is compatible with Python's behavior,
  e.g. `formatFloat(3.14159, precision = 0)` is now `3`, not `3.`.
- Global variable `lc` has been removed from sugar.nim.
- `distinctBase` has been moved from sugar.nim to typetraits and now implemented as
  compiler type trait instead of macro. `distinctBase` in sugar module is now deprecated.

### Breaking changes in the compiler

- Implicit conversions for `const` behave correctly now, meaning that code like
  `const SOMECONST = 0.int; procThatTakesInt32(SOMECONST)` will be illegal now.
  Simply write `const SOMECONST = 0` instead.



## Library additions

- `macros.newLit` now works for ref object types.
- `system.writeFile` has been overloaded to also support `openarray[byte]`.
- Added overloaded `strformat.fmt` macro that use specified characters as
  delimiter instead of '{' and '}'.
- introduced new procs in `tables.nim`: `OrderedTable.pop`, `CountTable.del`,
  `CountTable.pop`, `Table.pop`
- To `strtabs.nim`, added `StringTable.clear` overload that reuses the existing mode.


- Added `sugar.outplace` for turning in-place algorithms like `sort` and `shuffle` into
  operations that work on a copy of the data and return the mutated copy. As the existing
  `sorted` does.
- Added `sugar.collect` that does comprehension for seq/set/table collections.

- Added `sugar.capture` for capturing some local loop variables when creating a closure.
  This is an enhanced version of `closureScope`.

- Added `typetraits.lenTuple` to get number of elements of a tuple/type tuple,
  and `typetraits.get` to get the ith element of a type tuple.
- Added `typetraits.genericParams` to return a tuple of generic params from a generic instantiation

- Added `os.normalizePathEnd` for additional path sanitization.

- Added `times.fromUnixFloat,toUnixFloat`, subsecond resolution versions of `fromUnix`,`toUnixFloat`.

- Added `wrapnils` module for chains of field-access and indexing where the LHS can be nil.
  This simplifies code by reducing need for if-else branches around intermediate maybe nil values.
  Eg: `echo ?.n.typ.kind`

## Library changes

- `asyncdispatch.drain` now properly takes into account `selector.hasPendingOperations`
  and only returns once all pending async operations are guaranteed to have completed.
- `asyncdispatch.drain` now consistently uses the passed timeout value for all
  iterations of the event loop, and not just the first iteration.
  This is more consistent with the other asyncdispatch apis, and allows
  `asyncdispatch.drain` to be more efficient.
- `base64.encode` and `base64.decode` was made faster by about 50%.
- `htmlgen` adds [MathML](https://wikipedia.org/wiki/MathML) support
  (ISO 40314).
- `macros.eqIdent` is now invariant to export markers and backtick quotes.
- `htmlgen.html` allows `lang` on the `<html>` tag and common valid attributes.
- `macros.basename` and `basename=` got support for `PragmaExpr`,
  so that an expression like `MyEnum {.pure.}` is handled correctly.


## Language additions

- An `align` pragma can now be used for variables and object fields, similar
  to the `alignas` declaration modifier in C/C++.

- `=sink` type bound operator is now optional. Compiler can now use combination
  of `=destroy` and `copyMem` to move objects efficiently.


## Language changes

- Unsigned integer operators have been fixed to allow promotion of the first operand.
- Conversions to unsigned integers are unchecked at runtime, imitating earlier Nim
  versions. The documentation was improved to acknowledge this special case.
  See https://github.com/nim-lang/RFCs/issues/175 for more details.


### Tool changes



### Compiler changes

- JS target indent is all spaces, instead of mixed spaces and tabs, for
  generated JavaScript.
- The Nim compiler now supports the ``--asm`` command option for easier
  inspection of the produced assembler code.
- The Nim compiler now supports a new pragma called ``.localPassc`` to
  pass specific compiler options to the C(++) backend for the C(++) file
  that was produced from the current Nim module.


## Bugfixes

- The `FD` variant of `selector.unregister` for `ioselector_epoll` and
  `ioselector_select` now properly handle the `Event.User` select event type.
