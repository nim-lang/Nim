## v0.18.0 - dd/mm/yyyy

### Changes affecting backwards compatibility


- Arrays of char cannot be converted to ``cstring`` anymore, pointers to
  arrays of char can! This means ``$`` for arrays can finally exist
  in ``system.nim`` and do the right thing.
- ``echo`` now works with strings that contain ``\0`` (the binary zero is not
  shown) and ``nil`` strings are equal to empty strings.
- JSON: Deprecated `getBVal`, `getFNum`, and `getNum` in favour to
  `getBool`, `getFloat`, `getBiggestInt`. Also `getInt` procedure was added.
- `reExtended` is no longer default for the `re` constructor in the `re`
  module.
- The overloading rules changed slightly so that constrained generics are
  preferred over unconstrained generics. (Bug #6526)
- It is now possible to forward declare object types so that mutually
  recursive types can be created across module boundaries. See
  [package level objects](https://nim-lang.org/docs/manual.html#package-level-objects)
  for more information.
- The **unary** ``<`` is now deprecated, for ``.. <`` use ``..<`` for other usages
  use the ``pred`` proc.
- We changed how array accesses "from backwards" like ``a[^1]`` or ``a[0..^1]`` are
  implemented. These are now implemented purely in ``system.nim`` without compiler
  support. There is a new "heterogenous" slice type ``system.HSlice`` that takes 2
  generic parameters which can be ``BackwardsIndex`` indices. ``BackwardsIndex`` is
  produced by ``system.^``.
  This means if you overload ``[]`` or ``[]=`` you need to ensure they also work
  with ``system.BackwardsIndex`` (if applicable for the accessors).
- ``mod`` and bitwise ``and`` do not produce ``range`` subtypes anymore. This
  turned out to be more harmful than helpful and the language is simpler
  without this special typing rule.
- Added ``algorithm.rotateLeft``.
- ``rationals.toRational`` now uses an algorithm based on continued fractions.
  This means its results are more precise and it can't run into an infinite loop
  anymore.
- Added ``typetraits.$`` as an alias for ``typetraits.name``.
- ``os.getEnv`` now takes an optional ``default`` parameter that tells ``getEnv``
  what to return if the environment variable does not exist.
- Bodies of ``for`` loops now get their own scope:

```nim
  # now compiles:
  for i in 0..4:
    let i = i + 1
    echo i
```

- The parsing rules of ``if`` expressions were changed so that multiple
  statements are allowed in the branches. We found few code examples that
  now fail because of this change, but here is one:

```nim
  t[ti] = if exp_negative: '-' else: '+'; inc(ti)
```

This now needs to be written as:

```nim
  t[ti] = (if exp_negative: '-' else: '+'); inc(ti)
```

- To make Nim even more robust the system iterators ``..`` and ``countup``
  now only accept a single generic type ``T``. This means the following code
  doesn't die with an "out of range" error anymore:

```nim
  var b = 5.Natural
  var a = -5
  for i in a..b:
    echo i
```

- ``formatFloat``/``formatBiggestFloat`` now support formatting floats with zero
  precision digits. The previous ``precision = 0`` behavior (default formatting)
  is now available via ``precision = -1``.
- The ``nim doc`` command is now an alias for ``nim doc2``, the second version of
  the documentation generator. The old version 1 can still be accessed
  via the new ``nim doc0`` command.
- Added ``system.getStackTraceEntries`` that allows you to access the stack
  trace in a structured manner without string parsing.
- Added ``sequtils.mapLiterals`` for easier construction of array and tuple
  literals.
- Added ``parseutils.parseSaturatedNatural``.
- ``atomic`` and ``generic`` are no longer keywords in Nim. ``generic`` used to be
  an alias for ``concept``, ``atomic`` was not used for anything.
- Moved from stdlib into Nimble packages:
  - [``basic2d``](https://github.com/nim-lang/basic2d)
    _deprecated: use ``glm``, ``arraymancer``, ``neo``, or another package instead_
  - [``basic3d``](https://github.com/nim-lang/basic3d)
    _deprecated: use ``glm``, ``arraymancer``, ``neo``, or another package instead_
  - [``gentabs``](https://github.com/lcrees/gentabs)
  - [``libuv``](https://github.com/lcrees/libuv)
  - [``numeric``](https://github.com/lcrees/polynumeric)
  - [``poly``](https://github.com/lcrees/polynumeric)
  - [``pdcurses``](https://github.com/lcrees/pdcurses)
  - [``romans``](https://github.com/lcrees/romans)

- Added ``system.runnableExamples`` to make examples in Nim's documentation easier
  to write and test. The examples are tested as the last step of
  ``nim doc``.
- Nim's ``rst2html`` command now supports the testing of code snippets via an RST
  extension that we called ``:test:``::

  ```rst
    .. code-block:: nim
        :test:
      # shows how the 'if' statement works
      if true: echo "yes"
  ```
- The ``[]`` proc for strings now raises an ``IndexError`` exception when
  the specified slice is out of bounds. See issue
  [#6223](https://github.com/nim-lang/Nim/issues/6223) for more details.
  You can use ``substr(str, start, finish)`` to get the old behaviour back,
  see [this commit](https://github.com/nim-lang/nimbot/commit/98cc031a27ea89947daa7f0bb536bcf86462941f) for an example.
- ``strutils.split`` and ``strutils.rsplit`` with an empty string and a
  separator now returns that empty string.
  See issue [#4377](https://github.com/nim-lang/Nim/issues/4377).
- The experimental overloading of the dot ``.`` operators now take
  an ``untyped``` parameter as the field name, it used to be
  a ``static[string]``. You can use ``when defined(nimNewDot)`` to make
  your code work with both old and new Nim versions.
  See [special-operators](https://nim-lang.org/docs/manual.html#special-operators)
  for more information.
- Added ``macros.unpackVarargs``.
- The memory manager now uses a variant of the TLSF algorithm that has much
  better memory fragmentation behaviour. According
  to [http://www.gii.upv.es/tlsf/](http://www.gii.upv.es/tlsf/) the maximum
  fragmentation measured is lower than 25%. As a nice bonus ``alloc`` and
  ``dealloc`` became O(1) operations.
- The behavior of ``$`` has been changed for all standard library collections. The
  collection-to-string implementations now perform proper quoting and escaping of
  strings and chars.
- The ``random`` procs in ``random.nim`` have all been deprecated. Instead use
  the new ``rand`` procs. The module now exports the state of the random
  number generator as type ``Rand`` so multiple threads can easily use their
  own random number generators that do not require locking. For more information
  about this rename see issue [#6934](https://github.com/nim-lang/Nim/issues/6934)
- The compiler is now more consistent in its treatment of ambiguous symbols:
  Types that shadow procs and vice versa are marked as ambiguous (bug #6693).
- ``yield`` (or ``await`` which is mapped to ``yield``) never worked reliably
  in an array, seq or object constructor and is now prevented at compile-time.
- For string formatting / interpolation a new module
  called [strformat](https://nim-lang.org/docs/strformat.html) has been added
  to the stdlib.
- codegenDecl pragma now works for the JavaScript backend. It returns an empty string for
  function return type placeholders.
- Asynchronous programming for the JavaScript backend using the `asyncjs` module.
- Extra semantic checks for procs with noreturn pragma: return type is not allowed,
  statements after call to noreturn procs are no longer allowed.
- Noreturn proc calls and raising exceptions branches are now skipped during common type
  deduction in if and case expressions. The following code snippets now compile:
```nim
import strutils
let str = "Y"
let a = case str:
  of "Y": true
  of "N": false
  else: raise newException(ValueError, "Invalid boolean")
let b = case str:
  of nil, "": raise newException(ValueError, "Invalid boolean")
  elif str.startsWith("Y"): true
  elif str.startsWith("N"): false
  else: false
let c = if str == "Y": true
  elif str == "N": false
  else:
    echo "invalid bool"
    quit("this is the end")
```
- Proc [toCountTable](https://nim-lang.org/docs/tables.html#toCountTable,openArray[A]) now produces a `CountTable` with values correspoding to the number of occurrences of the key in the input. It used to produce a table with all values set to `1`.

Counting occurrences in a sequence used to be:

```nim
let mySeq = @[1, 2, 1, 3, 1, 4]
var myCounter = initCountTable[int]()

for item in mySeq:
  myCounter.inc item
```

Now, you can simply do:

```nim
let
  mySeq = @[1, 2, 1, 3, 1, 4]
  myCounter = mySeq.toCountTable()
```

- Added support for casting between integers of same bitsize in VM (compile time and nimscript).
  This allow to among other things to reinterpret signed integers as unsigned.
