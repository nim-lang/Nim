Version 0.11.0 released
=======================

.. container:: metadata

  Posted by Dominik Picheta on 30/04/2015

With this release we are one step closer to reaching version 1.0 and by
extension the persistence of the Nim specification. As mentioned in the
previous release notes, starting with version 1.0, we will not be introducing
any more breaking changes to Nim.

The *language* itself is very close to 1.0, the primary area that requires
more work is the standard library.

Take a look at the `download <download.html>`_ page for binaries (Windows-only)
and 0.11.0 snapshots of the source code. The Windows installer now also
includes `Aporia <https://github.com/nim-lang/aporia>`_,
`Nimble <https://github.com/nim-lang/nimble>`_ and other useful tools to get
you started with Nim.

What's left to be done
~~~~~~~~~~~~~~~~~~~~~~

The 1.0 release is expected by the end of this year. Rumors say it will be in
summer 2015. What's left:

* Bug fixes, bug fixes, bug fixes, in particular:
  - The remaining bugs of the lambda lifting pass that is responsible to enable
    closures and closure iterators need to be fixed.
  - ``concept`` needs to be refined, a nice name for the feature is not enough.
  - Destructors need to be refined.
  - ``static[T]`` needs to be fixed.
  - Finish the implementation of the 'parallel' statement.
* ``immediate`` templates and macros will be deprecated as these will soon be
  completely unnecessary, instead the ``typed`` or ``untyped`` metatypes can
  be used.
* More of the standard library should be moved to Nimble packages and what's
  left should use the features we have for concurrency and parallelism.



Changes affecting backwards compatibility
-----------------------------------------

- Parameter names are finally properly ``gensym``'ed. This can break
  templates though that used to rely on the fact that they are not.
  (Bug #1915.) This means this doesn't compile anymore:

.. code-block:: nim

  template doIt(body: stmt) {.immediate.} =
    # this used to inject the 'str' parameter:
    proc res(str: string) =
      body

  doIt:
    echo str # Error: undeclared identifier: 'str'
..

  This used to inject the ``str`` parameter into the scope of the body.
  Declare the ``doIt`` template as ``immediate, dirty`` to get the old
  behaviour.
- Tuple field names are not ignored anymore, this caused too many problems
  in practice so now the behaviour is as it was for version 0.9.6: If field
  names exist for the tuple type, they are checked.
- ``logging.level`` and ``logging.handlers`` are no longer exported.
  ``addHandler``, ``getHandlers``, ``setLogFilter`` and ``getLogFilter``
  should be used instead.
- ``nim idetools`` has been replaced by a separate
  tool `nimsuggest <0.11.0/nimsuggest.html>`_.
- *arrow like* operators are not right associative anymore and are required
  to end with either ``->``, ``~>`` or
  ``=>``, not just ``>``. Examples of operators still considered arrow like:
  ``->``, ``==>``, ``+=>``. On the other hand, the following operators are now
  considered regular operators again: ``|>``, ``-+>``, etc.
- Typeless parameters are now only allowed in templates and macros. The old
  way turned out to be too error-prone.
- The 'addr' and 'type' operators are now parsed as unary function
  application. This means ``type(x).name`` is now parsed as ``(type(x)).name``
  and not as ``type((x).name)``. Note that this also affects the AST
  structure; for immediate macro parameters ``nkCall('addr', 'x')`` is
  produced instead of ``nkAddr('x')``.
- ``concept`` is now a keyword and is used instead of ``generic``.
- The ``inc``, ``dec``, ``+=``, ``-=`` builtins now produce OverflowError
  exceptions. This means code like the following:

.. code-block:: nim
  var x = low(T)
  while x <= high(T):
    echo x
    inc x

Needs to be replaced by something like this:

.. code-block:: nim
  var x = low(T).int
  while x <= high(T).int:
    echo x.T
    inc x

- **Negative indexing for slicing does not work anymore!** Instead
  of ``a[0.. -1]`` you can
  use ``a[0.. ^1]``. This also works with accessing a single
  element ``a[^1]``. Note that we cannot detect this reliably as it is
  determined at **runtime** whether negative indexing is used!
  ``a[0.. -1]`` now produces the empty string/sequence.
- The compiler now warns about code like ``foo +=1`` which uses inconsistent
  spacing around binary operators. Later versions of the language will parse
  these as unary operators instead so that ``echo $foo`` finally can do what
  people expect it to do.
- ``system.untyped`` and ``system.typed`` have been introduced as aliases
  for ``expr`` and ``stmt``. The new names capture the semantics much better
  and most likely  ``expr`` and ``stmt`` will be deprecated in favor of the
  new names.
- The ``split`` method in module ``re`` has changed. It now handles the case
  of matches having a length of 0, and empty strings being yielded from the
  iterator. A notable change might be that a pattern being matched at the
  beginning and end of a string, will result in an empty string being produced
  at the start and the end of the iterator.
- The compiler and nimsuggest now count columns starting with 1, not 0 for
  consistency with the rest of the world.


Language Additions
------------------

- For empty ``case object`` branches ``discard`` can finally be used instead
  of ``nil``.
- Automatic dereferencing is now done for the first argument of a routine
  call if overloading resolution produces no match otherwise. This feature
  has to be enabled with
  the `experimental <0.11.0/manual.html#pragmas-experimental-pragma>`_ pragma.
- Objects that do not use inheritance nor ``case`` can be put into ``const``
  sections. This means that finally this is possible and produces rather
  nice code:

.. code-block:: nim
  import tables

  const
    foo = {"ah": "finally", "this": "is", "possible.": "nice!"}.toTable()


- Ordinary parameters can follow after a varargs parameter. This means the
  following is finally accepted by the compiler:

.. code-block:: nim
  template takesBlock(a, b: int, x: varargs[expr]; blck: stmt) =
    blck
    echo a, b

  takesBlock 1, 2, "some", 0.90, "random stuff":
    echo "yay"

- Overloading by 'var T' is now finally possible:

.. code-block:: nim
  proc varOrConst(x: var int) = echo "var"
  proc varOrConst(x: int) = echo "const"

  var x: int
  varOrConst(x) # "var"
  varOrConst(45) # "const"

- Array and seq indexing can now use the builtin ``^`` operator to access
  things from backwards: ``a[^1]`` is like Python's ``a[-1]``.
- A first version of the specification and implementation of the overloading
  of the assignment operator has arrived!
- ``system.len`` for strings and sequences now returns 0 for nil.

- A single underscore can now be used to discard values when unpacking tuples:

.. code-block:: nim
  let (path, _, _) = os.splitFile("path/file.ext")


- ``marshal.$$`` and ``marshal.to`` can be executed at compile-time.
- Interoperability with C++ improved tremendously; C++'s templates and
  operators can be wrapped directly. See
  `this <0.11.0/nimc.html#additional-features-importcpp-pragma>`_
  for more information.
- ``macros.getType`` can be used to query an AST's type at compile-time. This
  enables more powerful macros, for instance *currying* can now be done with
  a macro.


Library additions
-----------------

- ``reversed`` proc added to the ``unicode`` module.
- Added multipart param to httpclient's ``post`` and ``postContent`` together
  with a ``newMultipartData`` proc.
- Added `%*` operator for JSON.
- The compiler is now available as Nimble package for c2nim.
- Added ``..^`` and ``..<`` templates to system so that the rather annoying
  space between ``.. <`` and ``.. ^`` is not necessary anymore.
- Added ``system.xlen`` for strings and sequences to get back the old ``len``
  operation that doesn't check for ``nil`` for efficiency.
- Added sexp.nim to parse and generate sexp.


Bugfixes
--------

- Fixed internal compiler error when using ``char()`` in an echo call
  (`#1788 <https://github.com/Araq/Nim/issues/1788>`_).
- Fixed Windows cross-compilation on Linux.
- Overload resolution now works for types distinguished only by a
  ``static[int]`` param
  (`#1056 <https://github.com/Araq/Nim/issues/1056>`_).
- Other fixes relating to generic types and static params.
- Fixed some compiler crashes with unnamed tuples
  (`#1774 <https://github.com/Araq/Nim/issues/1774>`_).
- Fixed ``channels.tryRecv`` blocking
  (`#1816 <https://github.com/Araq/Nim/issues/1816>`_).
- Fixed generic instantiation errors with ``typedesc``
  (`#419 <https://github.com/Araq/Nim/issues/419>`_).
- Fixed generic regression where the compiler no longer detected constant
  expressions properly (`#544 <https://github.com/Araq/Nim/issues/544>`_).
- Fixed internal error with generic proc using ``static[T]`` in a specific
  way (`#1049 <https://github.com/Araq/Nim/issues/1049>`_).
- More fixes relating to generics (`#1820 <https://github.com/Araq/Nim/issues/1820>`_,
  `#1050 <https://github.com/Araq/Nim/issues/1050>`_,
  `#1859 <https://github.com/Araq/Nim/issues/1859>`_,
  `#1858 <https://github.com/Araq/Nim/issues/1858>`_).
- Fixed httpclient to properly encode queries.
- Many fixes to the ``uri`` module.
- Async sockets are now closed on error.
- Fixes to httpclient's handling of multipart data.
- Fixed GC segfaults with asynchronous sockets
  (`#1796 <https://github.com/Araq/Nim/issues/1796>`_).
- Added more versions to openssl's DLL version list
  (`076f993 <https://github.com/Araq/Nim/commit/076f993>`_).
- Fixed shallow copy in iterators being broken
  (`#1803 <https://github.com/Araq/Nim/issues/1803>`_).
- ``nil`` can now be inserted into tables with the ``db_sqlite`` module
  (`#1866 <https://github.com/Araq/Nim/issues/1866>`_).
- Fixed "Incorrect assembler generated"
  (`#1907 <https://github.com/Araq/Nim/issues/1907>`_)
- Fixed "Expression templates that define macros are unusable in some contexts"
  (`#1903 <https://github.com/Araq/Nim/issues/1903>`_)
- Fixed "a second level generic subclass causes the compiler to crash"
  (`#1919 <https://github.com/Araq/Nim/issues/1919>`_)
- Fixed "nim 0.10.2 generates invalid AsyncHttpClient C code for MSVC "
  (`#1901 <https://github.com/Araq/Nim/issues/1901>`_)
- Fixed "1 shl n produces wrong C code"
  (`#1928 <https://github.com/Araq/Nim/issues/1928>`_)
- Fixed "Internal error on tuple yield"
  (`#1838 <https://github.com/Araq/Nim/issues/1838>`_)
- Fixed "ICE with template"
  (`#1915 <https://github.com/Araq/Nim/issues/1915>`_)
- Fixed "include the tool directory in the installer as it is required by koch"
  (`#1947 <https://github.com/Araq/Nim/issues/1947>`_)
- Fixed "Can't compile if file location contains spaces on Windows"
  (`#1955 <https://github.com/Araq/Nim/issues/1955>`_)
- Fixed "List comprehension macro only supports infix checks as guards"
  (`#1920 <https://github.com/Araq/Nim/issues/1920>`_)
- Fixed "wrong field names of compatible tuples in generic types"
  (`#1910 <https://github.com/Araq/Nim/issues/1910>`_)
- Fixed "Macros within templates no longer work as expected"
  (`#1944 <https://github.com/Araq/Nim/issues/1944>`_)
- Fixed "Compiling for Standalone AVR broken in 0.10.2"
  (`#1964 <https://github.com/Araq/Nim/issues/1964>`_)
- Fixed "Compiling for Standalone AVR broken in 0.10.2"
  (`#1964 <https://github.com/Araq/Nim/issues/1964>`_)
- Fixed "Code generation for mitems with tuple elements"
  (`#1833 <https://github.com/Araq/Nim/issues/1833>`_)
- Fixed "httpclient.HttpMethod should not be an enum"
  (`#1962 <https://github.com/Araq/Nim/issues/1962>`_)
- Fixed "terminal / eraseScreen() throws an OverflowError"
  (`#1906 <https://github.com/Araq/Nim/issues/1906>`_)
- Fixed "setControlCHook(nil) disables registered quit procs"
  (`#1546 <https://github.com/Araq/Nim/issues/1546>`_)
- Fixed "Unexpected idetools behaviour"
  (`#325 <https://github.com/Araq/Nim/issues/325>`_)
- Fixed "Unused lifted lambda does not compile"
  (`#1642 <https://github.com/Araq/Nim/issues/1642>`_)
- Fixed "'low' and 'high' don't work with cstring asguments"
  (`#2030 <https://github.com/Araq/Nim/issues/2030>`_)
- Fixed "Converting to int does not round in JS backend"
  (`#1959 <https://github.com/Araq/Nim/issues/1959>`_)
- Fixed "Internal error genRecordField 2 when adding region to pointer."
  (`#2039 <https://github.com/Araq/Nim/issues/2039>`_)
- Fixed "Macros fail to compile when compiled with --os:standalone"
  (`#2041 <https://github.com/Araq/Nim/issues/2041>`_)
- Fixed "Reading from {.compileTime.} variables can cause code generation to fail"
  (`#2022 <https://github.com/Araq/Nim/issues/2022>`_)
- Fixed "Passing overloaded symbols to templates fails inside generic procedures"
  (`#1988 <https://github.com/Araq/Nim/issues/1988>`_)
- Fixed "Compiling iterator with object assignment in release mode causes "var not init""
  (`#2023 <https://github.com/Araq/Nim/issues/2023>`_)
- Fixed "calling a large number of macros doing some computation fails"
  (`#1989 <https://github.com/Araq/Nim/issues/1989>`_)
- Fixed "Can't get Koch to install nim under Windows"
  (`#2061 <https://github.com/Araq/Nim/issues/2061>`_)
- Fixed "Template with two stmt parameters segfaults compiler"
  (`#2057 <https://github.com/Araq/Nim/issues/2057>`_)
- Fixed "`noSideEffect` not affected by `echo`"
  (`#2011 <https://github.com/Araq/Nim/issues/2011>`_)
- Fixed "Compiling with the cpp backend ignores --passc"
  (`#1601 <https://github.com/Araq/Nim/issues/1601>`_)
- Fixed "Put untyped procedure parameters behind the experimental pragma"
  (`#1956 <https://github.com/Araq/Nim/issues/1956>`_)
- Fixed "generic regression"
  (`#2073 <https://github.com/Araq/Nim/issues/2073>`_)
- Fixed "generic regression"
  (`#2073 <https://github.com/Araq/Nim/issues/2073>`_)
- Fixed "Regression in template lookup with generics"
  (`#2004 <https://github.com/Araq/Nim/issues/2004>`_)
- Fixed "GC's growObj is wrong for edge cases"
  (`#2070 <https://github.com/Araq/Nim/issues/2070>`_)
- Fixed "Compiler internal error when creating an array out of a typeclass"
  (`#1131 <https://github.com/Araq/Nim/issues/1131>`_)
- Fixed "GC's growObj is wrong for edge cases"
  (`#2070 <https://github.com/Araq/Nim/issues/2070>`_)
- Fixed "Invalid Objective-C code generated when calling class method"
  (`#2068 <https://github.com/Araq/Nim/issues/2068>`_)
- Fixed "walkDirRec Error"
  (`#2116 <https://github.com/Araq/Nim/issues/2116>`_)
- Fixed "Typo in code causes compiler SIGSEGV in evalAtCompileTime"
  (`#2113 <https://github.com/Araq/Nim/issues/2113>`_)
- Fixed "Regression on exportc"
  (`#2118 <https://github.com/Araq/Nim/issues/2118>`_)
- Fixed "Error message"
  (`#2102 <https://github.com/Araq/Nim/issues/2102>`_)
- Fixed "hint[path] = off not working in nim.cfg"
  (`#2103 <https://github.com/Araq/Nim/issues/2103>`_)
- Fixed "compiler crashes when getting a tuple from a sequence of generic tuples"
  (`#2121 <https://github.com/Araq/Nim/issues/2121>`_)
- Fixed "nim check hangs with when"
  (`#2123 <https://github.com/Araq/Nim/issues/2123>`_)
- Fixed "static[T] param in nested type resolve/caching issue"
  (`#2125 <https://github.com/Araq/Nim/issues/2125>`_)
- Fixed "repr should display ``\0``"
  (`#2124 <https://github.com/Araq/Nim/issues/2124>`_)
- Fixed "'nim check' never ends in case of recursive dependency "
  (`#2051 <https://github.com/Araq/Nim/issues/2051>`_)
- Fixed "From macros: Error: unhandled exception: sons is not accessible"
  (`#2167 <https://github.com/Araq/Nim/issues/2167>`_)
- Fixed "`fieldPairs` doesn't work inside templates"
  (`#1902 <https://github.com/Araq/Nim/issues/1902>`_)
- Fixed "fields iterator misbehavior on break statement"
  (`#2134 <https://github.com/Araq/Nim/issues/2134>`_)
- Fixed "Fix for compiler not building anymore since #c3244ef1ff"
  (`#2193 <https://github.com/Araq/Nim/issues/2193>`_)
- Fixed "JSON parser fails in cpp output mode"
  (`#2199 <https://github.com/Araq/Nim/issues/2199>`_)
- Fixed "macros.getType mishandles void return"
  (`#2211 <https://github.com/Araq/Nim/issues/2211>`_)
- Fixed "Regression involving templates instantiated within generics"
  (`#2215 <https://github.com/Araq/Nim/issues/2215>`_)
- Fixed ""Error: invalid type" for 'not nil' on generic type."
  (`#2216 <https://github.com/Araq/Nim/issues/2216>`_)
- Fixed "--threads:on breaks async"
  (`#2074 <https://github.com/Araq/Nim/issues/2074>`_)
- Fixed "Type mismatch not always caught, can generate bad code for C backend."
  (`#2169 <https://github.com/Araq/Nim/issues/2169>`_)
- Fixed "Failed C compilation when storing proc to own type in object"
  (`#2233 <https://github.com/Araq/Nim/issues/2233>`_)
- Fixed "Unknown line/column number in constant declaration type conversion error"
  (`#2252 <https://github.com/Araq/Nim/issues/2252>`_)
- Fixed "Adding {.compile.} fails if nimcache already exists."
  (`#2247 <https://github.com/Araq/Nim/issues/2247>`_)
- Fixed "Two different type names generated for a single type (C backend)"
  (`#2250 <https://github.com/Araq/Nim/issues/2250>`_)
- Fixed "Ambigous call when it should not be"
  (`#2229 <https://github.com/Araq/Nim/issues/2229>`_)
- Fixed "Make sure we can load root urls"
  (`#2227 <https://github.com/Araq/Nim/issues/2227>`_)
- Fixed "Failure to slice a string with an int subrange type"
  (`#794 <https://github.com/Araq/Nim/issues/794>`_)
- Fixed "documentation error"
  (`#2205 <https://github.com/Araq/Nim/issues/2205>`_)
- Fixed "Code growth when using `const`"
  (`#1940 <https://github.com/Araq/Nim/issues/1940>`_)
- Fixed "Instances of generic types confuse overload resolution"
  (`#2220 <https://github.com/Araq/Nim/issues/2220>`_)
- Fixed "Compiler error when initializing sdl2's EventType"
  (`#2316 <https://github.com/Araq/Nim/issues/2316>`_)
- Fixed "Parallel disjoint checking can't handle `<`, `items`, or arrays"
  (`#2287 <https://github.com/Araq/Nim/issues/2287>`_)
- Fixed "Strings aren't copied in parallel loop"
  (`#2286 <https://github.com/Araq/Nim/issues/2286>`_)
- Fixed "JavaScript compiler crash with tables"
  (`#2298 <https://github.com/Araq/Nim/issues/2298>`_)
- Fixed "Range checker too restrictive"
  (`#1845 <https://github.com/Araq/Nim/issues/1845>`_)
- Fixed "Failure to slice a string with an int subrange type"
  (`#794 <https://github.com/Araq/Nim/issues/794>`_)
- Fixed "Remind user when compiling in debug mode"
  (`#1868 <https://github.com/Araq/Nim/issues/1868>`_)
- Fixed "Compiler user guide has jumbled options/commands."
  (`#1819 <https://github.com/Araq/Nim/issues/1819>`_)
- Fixed "using `method`: 1 in a objects constructor fails when compiling"
  (`#1791 <https://github.com/Araq/Nim/issues/1791>`_)
