## v0.19.X - XX/XX/2018

### Changes affecting backwards compatibility

- The stdlib module ``future`` has been renamed to ``sugar``.
- ``macros.callsite`` is now deprecated. Since the introduction of ``varargs``
  parameters this became unnecessary.
- Anonymous tuples with a single element can now be written as ``(1,)`` with a
  trailing comma. The underlying AST is ``nnkTupleConstr(newLit 1)`` for this
  example. ``nnkTupleConstr`` is a new node kind your macros need to be able
  to deal with!
- Indexing into a ``cstring`` for the JS target is now mapped
  to ``charCodeAt``.
- Assignments that would "slice" an object into its supertype are now prevented
  at runtime. Use ``ref object`` with inheritance rather than ``object`` with
  inheritance to prevent this issue.
- The ``not nil`` type annotation now has to be enabled explicitly
  via ``{.experimental: "notnil".}`` as we are still not pleased with how this
  feature works with Nim's containers.
- The parser now warns about inconsistent spacing around binary operators as
  these can easily be confused with unary operators. This warning will likely
  become an error in the future.
- The ``'c`` and ``'C'`` suffix for octal literals is now deprecated to
  bring the language in line with the standard library (e.g. ``parseOct``).
- The dot style for import paths (e.g ``import path.to.module`` instead of
  ``import path/to/module``) has been deprecated.

#### Breaking changes in the standard library

- ``re.split`` for empty regular expressions now yields every character in
  the string which is what other programming languages chose to do.
- The returned tuple of ``system.instantiationInfo`` now has a third field
  containing the column of the instantiation.

- ``cookies.setCookie`` no longer assumes UTC for the expiration date.
- ``strutils.formatEng`` does not distinguish between ``nil`` and ``""``
  strings anymore for its ``unit`` parameter. Instead the space is controlled
  by a new parameter ``useUnitSpace``.

- The ``times.parse`` and ``times.format`` procs have been rewritten.
  The proc signatures are the same so it should generally not break anything.
  However, the new implementation is a bit stricter, which is a breaking change.
  For example ``parse("2017-01-01 foo", "yyyy-MM-dd")`` will now raise an error.

- ``proc `-`*(a, b: Time): int64`` in the ``times`` module has changed return type
  to ``times.Duration`` in order to support higher time resolutions.
  The proc is no longer deprecated.

- The ``times.Timezone`` is now an immutable ref-type that must be initialized
  with an explicit constructor (``newTimezone``).

- ``posix.Timeval.tv_sec`` has changed type to ``posix.Time``.

- ``math.`mod` `` for floats now behaves the same as ``mod`` for integers
  (previously it used floor division like Python). Use ``math.floorMod`` for the old behavior.

- For string inputs, ``unicode.isUpper`` and ``unicode.isLower`` now require a
  second mandatory parameter ``skipNonAlpha``.

- For string inputs, ``strutils.isUpperAscii`` and ``strutils.isLowerAscii`` now
  require a second mandatory parameter ``skipNonAlpha``.

- ``osLastError`` is now marked with ``sideEffect``
- The procs ``parseHexInt`` and ``parseOctInt`` now fail on empty strings
  and strings containing only valid prefixes, e.g. "0x" for hex integers.

- ``terminal.setCursorPos`` and ``terminal.setCursorXPos`` now work correctly
  with 0-based coordinates on POSIX (previously, you needed to use
  1-based coordinates on POSIX for correct behaviour; the Windows behaviour
  was always correct).

- ``lineInfoObj`` now returns absolute path instead of project path.
  It's used by ``lineInfo``, ``check``, ``expect``, ``require``, etc.

- ``net.sendTo`` no longer returns an int and now raises an ``OSError``.
- `threadpool`'s `await` and derivatives have been renamed to `blockUntil`
  to avoid confusions with `await` from the `async` macro.


#### Breaking changes in the compiler

- The undocumented ``#? braces`` parsing mode was removed.
- The undocumented PHP backend was removed.
- The default location of ``nimcache`` for the native code targets was
  changed. Read [the compiler user guide](https://nim-lang.org/docs/nimc.html#generated-c-code-directory)
  for more information.

### Library additions

- ``re.split`` now also supports the ``maxsplit`` parameter for consistency
  with ``strutils.split``.
- Added ``system.toOpenArray`` in order to support zero-copy slicing
  operations. This is currently not yet available for the JavaScript target.
- Added ``getCurrentDir``, ``findExe``, ``cpDir`` and  ``mvDir`` procs to
  ``nimscript``.
- The ``times`` module now supports up to nanosecond time resolution when available.
- Added the type ``times.Duration`` for representing fixed durations of time.
- Added the proc ``times.convert`` for converting between different time units,
  e.g days to seconds.
- Added the proc ``algorithm.binarySearch[T, K]`` with the ```cmp``` parameter.
- Added the proc ``algorithm.upperBound``.
- Added inverse hyperbolic functions, ``math.arcsinh``, ``math.arccosh`` and ``math.arctanh`` procs.
- Added cotangent, secant and cosecant procs ``math.cot``, ``math.sec`` and ``math.csc``; and their hyperbolic, inverse and inverse hyperbolic functions, ``math.coth``, ``math.sech``, ``math.csch``, ``math.arccot``, ``math.arcsec``, ``math.arccsc``, ``math.arccoth``, ``math.arcsech`` and ``math.arccsch`` procs.
- Added the procs ``math.floorMod`` and ``math.floorDiv`` for floor based integer division.
- Added the procs ``rationals.`div```, ``rationals.`mod```, ``rationals.floorDiv`` and ``rationals.floorMod`` for rationals.
- Added the proc ``math.prod`` for product of elements in openArray.
- Added the proc ``parseBinInt`` to parse a binary integer from a string, which returns the value.
- ``parseOct`` and ``parseBin`` in parseutils now also support the ``maxLen`` argument similar to ``parseHexInt``.
- Added the proc ``flush`` for memory mapped files.
- Added the ``MemMapFileStream``.
- Added a simple interpreting event parser template ``eventParser`` to the ``pegs`` module.
- Added ``macros.copyLineInfo`` to copy lineInfo from other node.
- Added ``system.ashr`` an arithmetic right shift for integers.

### Library changes

- ``macros.astGenRepr``, ``macros.lispRepr`` and ``macros.treeRepr``
  now escapes the content of string literals consistently.
- ``macros.NimSym`` and ``macros.NimIdent`` is now deprecated in favor
  of the more general ``NimNode``.
- ``macros.getImpl`` now includes the pragmas of types, instead of omitting them.
- ``macros.hasCustomPragma`` and ``macros.getCustomPragmaVal`` now
  also support ``ref`` and ``ptr`` types, pragmas on types and variant
  fields.
- ``system.SomeReal`` is now called ``SomeFloat`` for consistency and
  correctness.
- ``algorithm.smartBinarySearch`` and ``algorithm.binarySearch`` is
  now joined in ``binarySearch``. ``smartbinarySearch`` is now
  deprecated.
- The `terminal` module now exports additional procs for generating ANSI color
  codes as strings.
- Added the parameter ``val`` for the ``CritBitTree[int].inc`` proc.
- An exception raised from a ``test`` block of ``unittest`` now shows its type in
  error message.
- The ``compiler/nimeval`` API was rewritten to simplify the "compiler as an
  API". Using the Nim compiler and its VM as a scripting engine has never been
  easier. See ``tests/compilerapi/tcompilerapi.nim`` for an example of how to
  use the Nim VM in a native Nim application.
- Added the parameter ``val`` for the ``CritBitTree[T].incl`` proc.
- The proc ``tgamma`` was renamed to ``gamma``. ``tgamma`` is deprecated.
- The ``pegs`` module now exports getters for the fields of its ``Peg`` and ``NonTerminal``
  object types. ``Peg``s with child nodes now have the standard ``items`` and ``pairs``
  iterators.
- The ``accept`` socket procedure defined in the ``net`` module can now accept
  a nil socket.

### Language additions

- Dot calls combined with explicit generic instantiations can now be written
  as ``x.y[:z]`` which is transformed into ``y[z](x)`` by the parser.
- ``func`` is now an alias for ``proc {.noSideEffect.}``.
- In order to make ``for`` loops and iterators more flexible to use Nim now
  supports so called "for-loop macros". See
  the [manual](manual.html#macros-for-loop-macros) for more details.
  This feature enables a Python-like generic ``enumerate`` implementation.

- Case statements can now be rewritten via macros. See the [manual](manual.html#macros-case-statement-macros) for more information.
  This feature enables custom pattern matchers.


- the `typedesc` special type has been renamed to just `type`.
- `static` and `type` are now also modifiers similar to `ref` and `ptr`.
  They denote the special types `static[T]` and `type[T]`.
- Forcing compile-time evaluation with `static` now supports specifying
  the desired target type (as a concrete type or as a type class)
- The `type` operator now supports checking that the supplied expression
  matches an expected type constraint.

### Language changes

- The `importcpp` pragma now allows importing the listed fields of generic
  C++ types. Support for numeric parameters have also been added through
  the use of `static[T]` types.
  (#6415)

- Native C++ exceptions can now be imported with `importcpp` pragma.
  Imported exceptions can be raised and caught just like Nim exceptions.
  More details in language manual.

- ``nil`` for strings/seqs is finally gone. Instead the default value for
  these is ``"" / @[]``. Use ``--nilseqs:on`` for a transition period.

- Accessing the binary zero terminator in Nim's native strings
  is now invalid. Internally a Nim string still has the trailing zero for
  zero-copy interoperability with ``cstring``. Compile your code with the
  new switch ``--laxStrings:on`` if you need a transition period.

- The command syntax now supports keyword arguments after the first comma.

- Thread-local variables can now be declared inside procs. This implies all
  the effects of the ``global`` pragma.

- Nim now supports the ``except`` clause in the export statement.

- Range float types, example ``range[0.0 .. Inf]``. More details in language manual.
- The ``{.this.}`` pragma has been deprecated. It never worked within generics and
  we found the resulting code harder to read than the more explicit ``obj.field``
  syntax.
- "Memory regions" for pointer types have been deprecated, they were hardly used
  anywhere. Note that this has **nothing** to do with the ``--gc:regions`` switch
  of managing memory.

- The exception hierarchy was slightly reworked, ``SystemError`` was renamed to
  ``CatchableError`` and is the new base class for any exception that is guaranteed to
  be catchable. This change should have minimal impact on most existing Nim code.


### Tool changes

- ``jsondoc2`` has been renamed ``jsondoc``, similar to how ``doc2`` was renamed
  ``doc``. The old ``jsondoc`` can still be invoked with ``jsondoc0``.

### Compiler changes

- The VM's instruction count limit was raised to 3 million instructions in
  order to support more complex computations at compile-time.

- Support for hot code reloading has been implemented for the JavaScript
  target. To use it, compile your code with `--hotCodeReloading:on` and use a
  helper library such as LiveReload or BrowserSync.

- A new compiler option `--cppCompileToNamespace` puts the generated C++ code
  into the namespace "Nim" in order to avoid naming conflicts with existing
  C++ code. This is done for all Nim code - internal and exported.

- Added ``macros.getProjectPath`` and ``os.putEnv`` procs to Nim's virtual
  machine.

- The ``deadCodeElim`` option is now always turned on and the switch has no
  effect anymore, but is recognized for backwards compatibility.

- ``experimental`` is now a pragma / command line switch that can enable specific
  language extensions, it is not an all-or-nothing switch anymore.

- Nintendo Switch was added as a new platform target. See [the compiler user guide](https://nim-lang.org/docs/nimc.html)
  for more info.

- macros.bindSym now capable to accepts not only literal string or string constant expression.
  bindSym enhancement make it also can accepts computed string or ident node inside macros /
  compile time functions / static blocks. Only in templates / regular code it retains it's old behavior.
  This new feature can be accessed via {.experimental: "dynamicBindSym".} pragma/switch.

- On Posix systems the global system wide configuration is now put under ``/etc/nim/nim.cfg``,
  it used to be ``/etc/nim.cfg``. Usually it does not exist, however.

- On Posix systems the user configuration is now looked under ``$XDG_CONFIG_HOME/nim/nim.cfg``
  (if ``XDG_CONFIG_HOME`` is not defined, then under ``~/.config/nim/nim.cfg``). It used to be
  ``$XDG_CONFIG_DIR/nim.cfg`` (and ``~/.config/nim.cfg``).

  Similarly, on Windows, the user configuration is now looked under ``%APPDATA%/nim/nim.cfg``.
  This used to be ``%APPDATA%/nim.cfg``.

### Bugfixes
