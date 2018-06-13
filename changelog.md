## v0.19.X - XX/XX/2018

### Changes affecting backwards compatibility

- The stdlib module ``future`` has been renamed to ``sugar``.
- ``macros.callsite`` is now deprecated. Since the introduction of ``varargs``
  parameters this became unnecessary.
- Anonymous tuples with a single element can now be written as ``(1,)`` with a
  trailing comma. The underlying AST is ``nnkTupleConst(newLit 1)`` for this
  example. ``nnkTupleConstr`` is a new node kind your macros need to be able
  to deal with!
- Indexing into a ``cstring`` for the JS target is now mapped
  to ``charCodeAt``.
- Assignments that would "slice" an object into its supertype are now prevented
  at runtime. Use ``ref object`` with inheritance rather than ``object`` with
  inheritance to prevent this issue.
- The ``not nil`` type annotation now has to be enabled explicitly
  via ``{.experimental: "notnil"}`` as we are still not pleased with how this
  feature works with Nim's containers.
- The parser now warns about inconsistent spacing around binary operators as
  these can easily be confused with unary operators. This warning will likely
  become an error in the future.


#### Breaking changes in the standard library

- ``re.split`` for empty regular expressions now yields every character in
  the string which is what other programming languages chose to do.
- The returned tuple of ``system.instantiationInfo`` now has a third field
  containing the column of the instantiation.

- ``cookies.setCookie` no longer assumes UTC for the expiration date.
- ``strutils.formatEng`` does not distinguish between ``nil`` and ``""``
  strings anymore for its ``unit`` parameter. Instead the space is controlled
  by a new parameter ``useUnitSpace``.

- ``proc `-`*(a, b: Time): int64`` in the ``times`` module has changed return type
  to ``times.Duration`` in order to support higher time resolutions.
  The proc is no longer deprecated.
- ``posix.Timeval.tv_sec`` has changed type to ``posix.Time``.

- ``math.`mod` `` for floats now behaves the same as ``mod`` for integers
  (previously it used floor division like Python). Use ``math.floorMod`` for the old behavior.

- For string inputs, ``unicode.isUpper`` and ``unicode.isLower`` now require a
  second mandatory parameter ``skipNonAlpha``.

- For string inputs, ``strutils.isUpperAscii`` and ``strutils.isLowerAscii`` now
  require a second mandatory parameter ``skipNonAlpha``.

- The procs ``parseHexInt`` and ``parseOctInt`` now fail on empty strings
    and strings containing only valid prefixes, e.g. "0x" for hex integers.


#### Breaking changes in the compiler

- The undocumented ``#? braces`` parsing mode was removed.
- The undocumented PHP backend was removed.

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
- ``parseOct`` and ``parseBin`` in parseutils now also support the ``maxLen`` argument similar to ``parseHexInt``

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

### Language additions

- Dot calls combined with explicit generic instantiations can now be written
  as ``x.y[:z]`` which is transformed into ``y[z](x)`` by the parser.
- ``func`` is now an alias for ``proc {.noSideEffect.}``.
- In order to make ``for`` loops and iterators more flexible to use Nim now
  supports so called "for-loop macros". See
  the `manual <manual.html#macros-for-loop-macros>`_ for more details.

### Language changes

- The `importcpp` pragma now allows importing the listed fields of generic
  C++ types. Support for numeric parameters have also been added through
  the use of `static[T]` types.
  (#6415)

- Native C++ exceptions can now be imported with `importcpp` pragma.
  Imported exceptions can be raised and caught just like Nim exceptions.
  More details in language manual.

- ``nil`` for strings/seqs is finally gone. Instead the default value for
  these is ``"" / @[]``.

- Accessing the binary zero terminator in Nim's native strings
  is now invalid. Internally a Nim string still has the trailing zero for
  zero-copy interoperability with ``cstring``. Compile your code with the
  new switch ``--laxStrings:on`` if you need a transition period.

- The command syntax now supports keyword arguments after the first comma.

- Thread-local variables can now be declared inside procs. This implies all
  the effects of the `global` pragma.

- Nim now supports `except` clause in the export statement.

### Tool changes

- ``jsondoc2`` has been renamed ``jsondoc``, similar to how ``doc2`` was renamed
  ``doc``. The old ``jsondoc`` can still be invoked with ``jsondoc0``.

### Compiler changes

- The VM's instruction count limit was raised to 1 billion instructions in
  order to support more complex computations at compile-time.

- Support for hot code reloading has been implemented for the JavaScript
  target. To use it, compile your code with `--hotCodeReloading:on` and use a
  helper library such as LiveReload or BrowserSync.

- A new compiler option `--cppCompileToNamespace` puts the generated C++ code
  into the namespace "Nim" in order to avoid naming conflicts with existing
  C++ code. This is done for all Nim code - internal and exported.

- Added ``macros.getProjectPath`` and ``ospaths.putEnv`` procs to Nim's virtual
  machine.

- The ``deadCodeElim`` option is now always turned on and the switch has no
  effect anymore, but is recognized for backwards compatibility.

- ``experimental`` is now a pragma / command line switch that can enable specific
  language extensions, it is not an all-or-nothing switch anymore.

### Bugfixes
