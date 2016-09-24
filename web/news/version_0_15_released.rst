Version 0.15.0 released
=======================

.. container:: metadata

  Posted by Dominik Picheta on 17/09/2016

Some text here.

Changes affecting backwards compatibility
-----------------------------------------

- The ``json`` module uses an ``OrderedTable`` rather than a ``Table``
  for JSON objects.

- De-deprecated ``re.nim`` because we have too much code using it
  and it got the basic API right.

- ``split`` with ``set[char]`` as a delimiter in ``strutils.nim``
  no longer strips and splits characters out of the target string
  by the entire set of characters. Instead, it now behaves in a
  similar fashion to ``split`` with ``string`` and ``char``
  delimiters. Use ``splitWhitespace`` to get the old behaviour.
- The command invocation syntax will soon apply to open brackets
  and curlies too. This means that code like ``a [i]`` will be
  interpreted as ``a([i])`` and not as ``a[i]`` anymore. Likewise
  ``f (a, b)`` means that the tuple ``(a, b)`` is passed to ``f``.
  The compiler produces a warning for ``a [i]``::

    Warning: a [b] will be parsed as command syntax; spacing is deprecated

  See `<https://github.com/nim-lang/Nim/issues/3898>`_ for the relevant
  discussion.
- Overloading the special operators ``.``, ``.()``, ``.=``, ``()`` now
  should be enabled via ``{.experimental.}``.
- ``immediate`` templates and macros are now deprecated.
  Instead use ``untyped`` parameters.
- The metatype ``expr`` is deprecated. Use ``untyped`` instead.
- The metatype ``stmt`` is deprecated. Use ``typed`` instead.
- The compiler is now more picky when it comes to ``tuple`` types. The
  following code used to compile, now it's rejected:

.. code-block:: nim

  import tables
  var rocketaims = initOrderedTable[string, Table[tuple[k: int8, v: int8], int64] ]()
  rocketaims["hi"] = {(-1.int8, 0.int8): 0.int64}.toTable()

Instead be consistent in your tuple usage and use tuple names for tuples
that have tuple name:

.. code-block:: nim

  import tables
  var rocketaims = initOrderedTable[string, Table[tuple[k: int8, v: int8], int64] ]()
  rocketaims["hi"] = {(k: -1.int8, v: 0.int8): 0.int64}.toTable()

- Now when you compile console application for Windows, console output
  encoding is automatically set to UTF-8.

- Unhandled exceptions in JavaScript are now thrown regardless ``noUnhandledHandler``
  is defined. But now they do their best to provide a readable stack trace.

- In JavaScript ``system.alert`` is deprecated. Use ``dom.alert`` instead.

- ``AsyncHttpClient.headers`` type is now ``HttpHeaders``.

- The ``httpclient.request`` procedure that takes the ``httpMethod`` as a string
  value no longer requires this value to be prefixed with ``"http"``
  (or similar).


Library Additions
-----------------

- Added ``readHeaderRow`` and ``rowEntry`` to ``parsecsv.nim`` to provide
  a lightweight alternative to python's ``csv.DictReader``.
- Added ``setStdIoUnbuffered`` proc to ``system.nim`` to enable unbuffered I/O.

- Added ``center`` and ``rsplit`` to ``strutils.nim`` to
  provide similar Python functionality for Nim's strings.

- Added ``isTitle``, ``title``, ``swapCase``, ``isUpper``, ``toUpper``,
  ``isLower``, ``toLower``, ``isAlpha``, ``isSpace``, and ``capitalize``
  to ``unicode.nim`` to provide unicode aware case manipulation and case
  testing.

- Added a new module ``lib/pure/strmisc.nim`` to hold uncommon string
  operations. Currently contains ``partition``, ``rpartition``
  and ``expandTabs``.

- Split out ``walkFiles`` in ``os.nim`` to three separate procs in order
  to make a clear distinction of functionality. ``walkPattern`` iterates
  over both files and directories, while ``walkFiles`` now only iterates
  over files and ``walkDirs`` only iterates over directories.

- Added synchronous ``HttpClient`` in the ``httpclient`` module.

- Added a new macro called ``multisync`` allowing you to write procedures for
synchronous and asynchronous sockets with no duplication.

Compiler Additions
------------------

- The ``-d/--define`` flag can now optionally take a value to be used
  by code at compile time.

Nimscript Additions
-------------------

- Finally it's possible to dis/enable specific hints and warnings in
  Nimscript via the procs ``warning`` and ``hint``.
- Nimscript exports  a proc named ``patchFile`` which can be used to
  patch modules or include files for different Nimble packages, including
  the ``stdlib`` package.


Language Additions
------------------

- Added ``{.intdefine.}`` and ``{.strdefine.}`` macros to make use of
  (optional) compile time defines.
- If the first statement is an ``import system`` statement then ``system``
  is not imported implicitly anymore. This allows for code like
  ``import system except echo`` or ``from system import nil``.

Bugfixes
--------

- Fixed "RFC: should startsWith and endsWith work with characters?"
  (`#4252 <https://github.com/nim-lang/Nim/issues/4252>`_)

- Fixed "Feature request: unbuffered I/O"
  (`#2146 <https://github.com/nim-lang/Nim/issues/2146>`_)
- Fixed "clear() not implemented for CountTableRef"
  (`#4325 <https://github.com/nim-lang/Nim/issues/4325>`_)
- Fixed "Cannot close file opened async"
  (`#4334 <https://github.com/nim-lang/Nim/issues/4334>`_)
- Fixed "Feature Request: IDNA support"
  (`#3045 <https://github.com/nim-lang/Nim/issues/3045>`_)
- Fixed "Async: wrong behavior of boolean operations on futures"
  (`#4333 <https://github.com/nim-lang/Nim/issues/4333>`_)
- Fixed "os.walkFiles yields directories"
  (`#4280 <https://github.com/nim-lang/Nim/issues/4280>`_)
- Fixed "Fix #4392 and progress on #4170"
  (`#4393 <https://github.com/nim-lang/Nim/issues/4393>`_)
- Fixed "Await unable to wait futures from objects fields"
  (`#4390 <https://github.com/nim-lang/Nim/issues/4390>`_)
- Fixed "TMP variable name generation should be more stable"
  (`#4364 <https://github.com/nim-lang/Nim/issues/4364>`_)
- Fixed "nativesockets doesn't compile for Android 4.x (API v19 or older) because of gethostbyaddr"
  (`#4376 <https://github.com/nim-lang/Nim/issues/4376>`_)
- Fixed "no generic parameters allowed for ref"
  (`#4395 <https://github.com/nim-lang/Nim/issues/4395>`_)
- Fixed "split proc in strutils inconsistent for set[char]"
  (`#4305 <https://github.com/nim-lang/Nim/issues/4305>`_)
- Fixed "Problem with sets in devel"
  (`#4412 <https://github.com/nim-lang/Nim/issues/4412>`_)
- Fixed "Compiler crash when using seq[PNimrodNode] in macros"
  (`#537 <https://github.com/nim-lang/Nim/issues/537>`_)
- Fixed "ospaths should be marked for nimscript use only"
  (`#4249 <https://github.com/nim-lang/Nim/issues/4249>`_)
- Fixed "Repeated deepCopy() on a recursive data structure eventually crashes"
  (`#4340 <https://github.com/nim-lang/Nim/issues/4340>`_)
- Fixed "Analyzing destructor"
  (`#4371 <https://github.com/nim-lang/Nim/issues/4371>`_)
- Fixed "getType does not work anymore on a typedesc"
  (`#4462 <https://github.com/nim-lang/Nim/issues/4462>`_)
- Fixed "Error in rendering empty JSON array"
  (`#4399 <https://github.com/nim-lang/Nim/issues/4399>`_)
- Fixed "Segmentation fault when using async pragma on generic procs"
  (`#2377 <https://github.com/nim-lang/Nim/issues/2377>`_)
- Fixed "Forwarding does not work for generics,  | produces an implicit generic"
  (`#3055 <https://github.com/nim-lang/Nim/issues/3055>`_)
- Fixed "Inside a macro, the length of the `seq` data inside a `queue` does not increase and crashes"
  (`#4422 <https://github.com/nim-lang/Nim/issues/4422>`_)
- Fixed "compiler sigsegv while processing varargs"
  (`#4475 <https://github.com/nim-lang/Nim/issues/4475>`_)
- Fixed "JS codegen - strings are assigned by reference"
  (`#4471 <https://github.com/nim-lang/Nim/issues/4471>`_)
- Fixed "when statement doesn't verify syntax"
  (`#4301 <https://github.com/nim-lang/Nim/issues/4301>`_)
- Fixed ".this pragma doesn't work with .async procs"
  (`#4358 <https://github.com/nim-lang/Nim/issues/4358>`_)
- Fixed "type foo = range(...) crashes compiler"
  (`#4429 <https://github.com/nim-lang/Nim/issues/4429>`_)
- Fixed "Compiler crash"
  (`#2730 <https://github.com/nim-lang/Nim/issues/2730>`_)
- Fixed "Crash in compiler with static[int]"
  (`#3706 <https://github.com/nim-lang/Nim/issues/3706>`_)
- Fixed "Bad error message "could not resolve""
  (`#3548 <https://github.com/nim-lang/Nim/issues/3548>`_)
- Fixed "Roof operator on string in template crashes compiler  (Error: unhandled exception: sons is not accessible [FieldError])"
  (`#3545 <https://github.com/nim-lang/Nim/issues/3545>`_)
- Fixed "SIGSEGV during compilation with parallel block"
  (`#2758 <https://github.com/nim-lang/Nim/issues/2758>`_)
- Fixed "Codegen error with template and implicit dereference"
  (`#4478 <https://github.com/nim-lang/Nim/issues/4478>`_)
- Fixed "@ in importcpp should work with no-argument functions"
  (`#4496 <https://github.com/nim-lang/Nim/issues/4496>`_)
- Fixed "Regression: findExe raises"
  (`#4497 <https://github.com/nim-lang/Nim/issues/4497>`_)
- Fixed "Linking error - repeated symbols when splitting into modules"
  (`#4485 <https://github.com/nim-lang/Nim/issues/4485>`_)
- Fixed "Error: method is not a base"
  (`#4428 <https://github.com/nim-lang/Nim/issues/4428>`_)
- Fixed "Casting from function returning a tuple fails"
  (`#4345 <https://github.com/nim-lang/Nim/issues/4345>`_)
- Fixed "clang error with default nil parameter"
  (`#4328 <https://github.com/nim-lang/Nim/issues/4328>`_)
- Fixed "internal compiler error: openArrayLoc"
  (`#888 <https://github.com/nim-lang/Nim/issues/888>`_)
- Fixed "Can't forward declare async procs"
  (`#1970 <https://github.com/nim-lang/Nim/issues/1970>`_)
- Fixed "unittest.check and sequtils.allIt do not work together"
  (`#4494 <https://github.com/nim-lang/Nim/issues/4494>`_)
- Fixed "httpclient package can't make SSL requests over an HTTP proxy"
  (`#4520 <https://github.com/nim-lang/Nim/issues/4520>`_)
- Fixed "False positive warning "declared but not used" for enums."
  (`#4510 <https://github.com/nim-lang/Nim/issues/4510>`_)
- Fixed "Explicit conversions not using converters"
  (`#4432 <https://github.com/nim-lang/Nim/issues/4432>`_)

- Fixed "Unclear error message when importing"
  (`#4541 <https://github.com/nim-lang/Nim/issues/4541>`_)
- Fixed "Change console encoding to UTF-8 by default"
  (`#4417 <https://github.com/nim-lang/Nim/issues/4417>`_)

- Fixed "Typedesc ~= Generic notation does not work anymore!"
  (`#4534 <https://github.com/nim-lang/Nim/issues/4534>`_)
- Fixed "unittest broken?"
  (`#4555 <https://github.com/nim-lang/Nim/issues/4555>`_)
- Fixed "Operator "or" in converter types seems to crash the compiler."
  (`#4537 <https://github.com/nim-lang/Nim/issues/4537>`_)
- Fixed "nimscript failed to compile/run -- Error: cannot 'importc' variable at compile time"
  (`#4561 <https://github.com/nim-lang/Nim/issues/4561>`_)
- Fixed "Regression: identifier expected, but found ..."
  (`#4564 <https://github.com/nim-lang/Nim/issues/4564>`_)
- Fixed "varargs with transformation that takes var argument creates invalid c code"
  (`#4545 <https://github.com/nim-lang/Nim/issues/4545>`_)
- Fixed "Type mismatch when using empty tuple as generic parameter"
  (`#4550 <https://github.com/nim-lang/Nim/issues/4550>`_)
- Fixed "strscans"
  (`#4562 <https://github.com/nim-lang/Nim/issues/4562>`_)
- Fixed "getTypeImpl crashes (SIGSEGV) on variant types"
  (`#4526 <https://github.com/nim-lang/Nim/issues/4526>`_)
- Fixed "Wrong result of sort in VM"
  (`#4065 <https://github.com/nim-lang/Nim/issues/4065>`_)
- Fixed "I can't call the random[T](x: Slice[T]): T"
  (`#4353 <https://github.com/nim-lang/Nim/issues/4353>`_)
- Fixed "invalid C code generated (function + block + empty tuple)"
  (`#4505 <https://github.com/nim-lang/Nim/issues/4505>`_)

- Fixed "performance issue: const Table make a copy at runtime lookup."
  (`#4354 <https://github.com/nim-lang/Nim/issues/4354>`_)
- Fixed "Compiler issue: libraries without absolute paths cannot be found correctly"
  (`#4568 <https://github.com/nim-lang/Nim/issues/4568>`_)
- Fixed "Cannot use math.`^` with non-int types."
  (`#4574 <https://github.com/nim-lang/Nim/issues/4574>`_)
- Fixed "C codegen fails when constructing an array using an object constructor."
  (`#4582 <https://github.com/nim-lang/Nim/issues/4582>`_)
- Fixed "Visual Studio 10 unresolved external symbol _trunc(should we support VS2010?)"
  (`#4532 <https://github.com/nim-lang/Nim/issues/4532>`_)
- Fixed "Cannot pass generic subtypes to proc for generic supertype"
  (`#4528 <https://github.com/nim-lang/Nim/issues/4528>`_)
- Fixed "Lamda-lifting bug leading to crash."
  (`#4551 <https://github.com/nim-lang/Nim/issues/4551>`_)
- Fixed "First-class iterators declared as inline are compiled at Nim side (no error message) and fail at C"
  (`#2094 <https://github.com/nim-lang/Nim/issues/2094>`_)
- Fixed "VS2010-warning C4090 : 'function' : different 'const' qualifiers"
  (`#4590 <https://github.com/nim-lang/Nim/issues/4590>`_)
- Fixed "Regression: type mismatch with generics"
  (`#4589 <https://github.com/nim-lang/Nim/issues/4589>`_)
- Fixed "„can raise an unlisted exception“ when assigning nil as default value"
  (`#4593 <https://github.com/nim-lang/Nim/issues/4593>`_)
- Fixed "upcoming asyncdispatch.closeSocket is not GC-safe"
  (`#4606 <https://github.com/nim-lang/Nim/issues/4606>`_)
- Fixed "Visual Studio 10.0 compiler errors, 12.0 warning"
  (`#4459 <https://github.com/nim-lang/Nim/issues/4459>`_)
- Fixed "Exception of net.newContext: result.extraInternalIndex == 0  [AssertionError]"
  (`#4406 <https://github.com/nim-lang/Nim/issues/4406>`_)
- Fixed "error: redeclaration of 'result_115076' with no linkage"
  (`#3221 <https://github.com/nim-lang/Nim/issues/3221>`_)
- Fixed "Compiler crashes on conversion from int to float at compile time"
  (`#4619 <https://github.com/nim-lang/Nim/issues/4619>`_)
- Fixed "wrong number of arguments regression in devel"
  (`#4600 <https://github.com/nim-lang/Nim/issues/4600>`_)
- Fixed "importc $ has broken error message (and is not documented)"
  (`#4579 <https://github.com/nim-lang/Nim/issues/4579>`_)
- Fixed "Compiler segfaults on simple importcpp in js mode [regression]"
  (`#4632 <https://github.com/nim-lang/Nim/issues/4632>`_)
- Fixed "Critical reference counting codegen problem"
  (`#4653 <https://github.com/nim-lang/Nim/issues/4653>`_)
- Fixed "tables.nim needs lots of {.noSideEffect.}"
  (`#4254 <https://github.com/nim-lang/Nim/issues/4254>`_)
- Fixed "Capture variable error when using ``=>`` macro"
  (`#4658 <https://github.com/nim-lang/Nim/issues/4658>`_)
- Fixed "Enum from char: internal error getInt"
  (`#3606 <https://github.com/nim-lang/Nim/issues/3606>`_)
- Fixed "Compiler crashes in debug mode (no error in release mode) with Natural discriminant in object variants"
  (`#2865 <https://github.com/nim-lang/Nim/issues/2865>`_)
- Fixed "SIGSEGV when access field in const object variants"
  (`#4253 <https://github.com/nim-lang/Nim/issues/4253>`_)
- Fixed "varargs cannot be used with template converter."
  (`#4292 <https://github.com/nim-lang/Nim/issues/4292>`_)
- Fixed "Compiler crashes when borrowing $"
  (`#3928 <https://github.com/nim-lang/Nim/issues/3928>`_)
- Fixed "internal error: genMagicExpr: mArrPut"
  (`#4491 <https://github.com/nim-lang/Nim/issues/4491>`_)
- Fixed "Unhelpful error message on importc namespace collision"
  (`#4580 <https://github.com/nim-lang/Nim/issues/4580>`_)
- Fixed "Problem with openarrays and slices"
  (`#4179 <https://github.com/nim-lang/Nim/issues/4179>`_)
- Fixed "Removing lines from end of file then rebuilding does not rebuild [js only?]"
  (`#4656 <https://github.com/nim-lang/Nim/issues/4656>`_)
- Fixed "getCurrentException and getCurrentExceptionMsg do not work with JS"
  (`#4635 <https://github.com/nim-lang/Nim/issues/4635>`_)
- Fixed "generic proc parameter is not inferred if type parameter has specifier"
  (`#4672 <https://github.com/nim-lang/Nim/issues/4672>`_)
- Fixed "Cannot instantiate generic parameter when it is parent type parameter"
  (`#4673 <https://github.com/nim-lang/Nim/issues/4673>`_)
- Fixed "deepCopy doesn't work with inheritance after last commit"
  (`#4693 <https://github.com/nim-lang/Nim/issues/4693>`_)
- Fixed "Multi-methods don't work when passing ref to a different thread"
  (`#4689 <https://github.com/nim-lang/Nim/issues/4689>`_)
- Fixed "Infinite loop in effect analysis on generics"
  (`#4677 <https://github.com/nim-lang/Nim/issues/4677>`_)
- Fixed "SIGSEGV when compiling NimYAML tests"
  (`#4699 <https://github.com/nim-lang/Nim/issues/4699>`_)

- Fixed "Closing AsyncEvent now also unregisters it on non-Windows platforms"
    (`#4694 <https://github.com/nim-lang/Nim/issues/4694>`_)
- Fixed "Don't update handle in upcoming/asyncdispatch poll() if it was closed"
  (`#4697 <https://github.com/nim-lang/Nim/issues/4697>`_)
- Fixed "generated local variables declared outside block"
  (`#4721 <https://github.com/nim-lang/Nim/issues/4721>`_)
- Fixed "Footer Documentation links, & Community link point to the wrong place under news entries"
  (`#4529 <https://github.com/nim-lang/Nim/issues/4529>`_)
- Fixed "Jester's macro magic leads to incorrect C generation"
  (`#4088 <https://github.com/nim-lang/Nim/issues/4088>`_)
- Fixed "cas bug in atomics.nim"
  (`#3279 <https://github.com/nim-lang/Nim/issues/3279>`_)
- Fixed "nimgrep PEG not capturing the pattern 'A'"
  (`#4751 <https://github.com/nim-lang/Nim/issues/4751>`_)
- Fixed "GC assert triggers when assigning TableRef threadvar"
  (`#4640 <https://github.com/nim-lang/Nim/issues/4640>`_)
- Fixed ".this pragma conflicts with experimental ptr dereferencing when names conflict"
  (`#4671 <https://github.com/nim-lang/Nim/issues/4671>`_)
- Fixed "Generic procs accepting var .importcpp type do not work [regression]"
  (`#4625 <https://github.com/nim-lang/Nim/issues/4625>`_)
- Fixed "C Error on tuple assignment with array"
  (`#4626 <https://github.com/nim-lang/Nim/issues/4626>`_)
- Fixed "module securehash not gcsafe"
  (`#4760 <https://github.com/nim-lang/Nim/issues/4760>`_)
