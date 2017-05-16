Version 0.17.0 released
=======================

This release fixes the most important regressions introduced in 0.16.0. In
particular memory manager and channel bugs have been fixed. The NSIS based
installer is not provided anymore as the Nim website moved to ``https`` and
this causes NSIS downloads to fail.


Changelog
~~~~~~~~~

Changes affecting backwards compatibility
-----------------------------------------

- There are now two different HTTP response types, ``Response`` and
  ``AsyncResponse``. ``AsyncResponse``'s ``body`` accessor returns a
  ``Future[string]``!
- ``httpclient.request`` now respects ``maxRedirects`` option. Previously
  redirects were handled only by ``get`` and ``post`` procs.
- The IO routines now raise ``EOFError`` for the "end of file" condition.
  ``EOFError`` is a subtype of ``IOError`` and so it's easier to distinguish
  between "error during read" and "error due to EOF".
- A hash procedure has been added for ``cstring`` type in ``hashes`` module.
  Previously, hash of a ``cstring`` would be calculated as a hash of the
  pointer. Now the hash is calculated from the contents of the string, assuming
  ``cstring`` is a null-terminated string. Equal ``string`` and ``cstring``
  values produce an equal hash value.
- Macros accepting `varargs` arguments will now receive a node having the
  `nkArgList` node kind. Previous code expecting the node kind to be `nkBracket`
  may have to be updated.
- ``memfiles.open`` now closes file handleds/fds by default.  Passing
  ``allowRemap=true`` to ``memfiles.open`` recovers the old behavior.  The old
  behavior is only needed to call ``mapMem`` on the resulting ``MemFile``.
- ``posix.nim``: For better C++ interop the field
  ``sa_sigaction*: proc (x: cint, y: var SigInfo, z: pointer) {.noconv.}`` was
  changed
  to ``sa_sigaction*: proc (x: cint, y: ptr SigInfo, z: pointer) {.noconv.}``.
- The compiler doesn't infer effects for ``.base`` methods anymore. This means
  you need to annotate them with ``.gcsafe`` or similar to clearly declare
  upfront every implementation needs to fullfill these contracts.
- ``system.getAst templateCall(x, y)`` now typechecks the ``templateCall``
  properly. You need to patch your code accordingly.
- ``macros.getType`` and ``macros.getTypeImpl`` for an enum will now return an
  AST that is the same as what is used to define an enum.  Previously the AST
  returned had a repeated ``EnumTy`` node and was missing the initial pragma
  node (which is currently empty for an enum).
- ``macros.getTypeImpl`` now correctly returns the implementation for a symbol
  of type ``tyGenericBody``.
- If the dispatcher parameter's value used in multi method is ``nil``,
  a ``NilError`` exception is raised. The old behavior was that the method
  would be a ``nop`` then.
- ``posix.nim``: the family of ``ntohs`` procs now takes unsigned integers
  instead of signed integers.
- In Nim identifiers en-dash (Unicode point U+2013) is not an alias for the
  underscore anymore. Use underscores and fix your programming font instead.
- When the ``requiresInit`` pragma is applied to a record type, future versions
  of Nim will also require you to initialize all the fields of the type during
  object construction. For now, only a warning will be produced.
- The Object construction syntax now performs a number of additional safety
  checks. When fields within case objects are initialiazed, the compiler will
  now demand that the respective discriminator field has a matching known
  compile-time value.
- On posix, the results of `waitForExit`, `peekExitCode`, `execCmd` will return
  128 + signal number if the application terminates via signal.
- ``ospaths.getConfigDir`` now conforms to the XDG Base Directory specification
  on non-Windows OSs. It returns the value of the XDG_CONFIG_DIR environment
  variable if it is set, and returns the default configuration directory,
  "~/.config/", otherwise.

Library Additions
-----------------

- Added ``system.onThreadDestruction``.
- Added ``dial`` procedure to networking modules: ``net``, ``asyncdispatch``,
  ``asyncnet``. It merges socket creation, address resolution, and connection
  into single step. When using ``dial``, you don't have to worry about
  IPv4 vs IPv6 problem. ``httpclient`` now supports IPv6.

Tool Additions
--------------

- The ``finish`` tool can now download MingW for you should it not find a
  working MingW installation.


Compiler Additions
------------------

- The name mangling rules used by the C code generator changed. Most of the time
  local variables and parameters are not mangled at all anymore. This improves
  debugging experience.
- The compiler produces explicit name mangling files when ``--debugger:native``
  is enabled. Debuggers can read these ``.ndi`` files in order to improve
  debugging Nim code.


Language Additions
------------------

- The ``try`` statement's ``except`` branches now support the binding of a
caught exception to a variable:

.. code-block:: nim
  try:
    raise newException(Exception, "Hello World")
  except Exception as exc:
    echo(exc.msg)

This replaces the ``getCurrentException`` and ``getCurrentExceptionMsg()``
procedures, although these procedures will remain in the stdlib for the
foreseeable future. This new language feature is actually implemented using
these procedures.

In the near future we will be converting all exception types to refs to
remove the need for the ``newException`` template.

- A new pragma ``.used`` can be used for symbols to prevent
the "declared but not used" warning. More details can be
found `here <http://nim-lang.org/docs/manual.html#pragmas-used-pragma>`_.
- The popular "colon block of statements" syntax is now also supported for
  ``let`` and ``var`` statements and assignments:

.. code-block:: nim
  template ve(value, effect): untyped =
    effect
    val

  let x = ve(4):
    echo "welcome to Nim!"

This is particularly useful for DSLs that help in tree construction.


Language changes
----------------

- The ``.procvar`` annotation is not required anymore. That doesn't mean you
  can pass ``system.$`` to ``map`` just yet though.


Bugfixes
--------

The list below has been generated based on the commits in Nim's git
repository. As such it lists only the issues which have been closed
via a commit, for a full list see
`this link on Github <https://github.com/nim-lang/Nim/issues?utf8=%E2%9C%93&q=is%3Aissue+closed%3A%222017-01-07+..+2017-02-06%22+>`_.

- Fixed "Weird compilation bug"
  (`#4884 <https://github.com/nim-lang/Nim/issues/4884>`_)
- Fixed "Return by arg optimization does not set result to default value"
  (`#5098 <https://github.com/nim-lang/Nim/issues/5098>`_)
- Fixed "upcoming asyncdispatch doesn't remove recv callback if remote side closed socket"
  (`#5128 <https://github.com/nim-lang/Nim/issues/5128>`_)
- Fixed "compiler bug, executable writes into wrong memory"
  (`#5218 <https://github.com/nim-lang/Nim/issues/5218>`_)
- Fixed "Module aliasing fails when multiple modules have the same original name"
  (`#5112 <https://github.com/nim-lang/Nim/issues/5112>`_)
- Fixed "JS: var argument + case expr with arg = bad codegen"
  (`#5244 <https://github.com/nim-lang/Nim/issues/5244>`_)
- Fixed "compiler reject proc's param shadowing inside template"
  (`#5225 <https://github.com/nim-lang/Nim/issues/5225>`_)
- Fixed "const value not accessible in proc"
  (`#3434 <https://github.com/nim-lang/Nim/issues/3434>`_)
- Fixed "Compilation regression 0.13.0 vs 0.16.0 in compile-time evaluation"
  (`#5237 <https://github.com/nim-lang/Nim/issues/5237>`_)
- Fixed "Regression: JS: wrong field-access codegen"
  (`#5234 <https://github.com/nim-lang/Nim/issues/5234>`_)
- Fixed "fixes #5234"
  (`#5240 <https://github.com/nim-lang/Nim/issues/5240>`_)
- Fixed "JS Codegen: duplicated fields in object constructor"
  (`#5271 <https://github.com/nim-lang/Nim/issues/5271>`_)
- Fixed "RFC: improving JavaScript FFI"
  (`#4873 <https://github.com/nim-lang/Nim/issues/4873>`_)
- Fixed "Wrong result type when using bitwise and"
  (`#5216 <https://github.com/nim-lang/Nim/issues/5216>`_)
- Fixed "upcoming.asyncdispatch is prone to memory leaks"
  (`#5290 <https://github.com/nim-lang/Nim/issues/5290>`_)
- Fixed "Using threadvars leads to crash on Windows when threads are created/destroyed"
  (`#5301 <https://github.com/nim-lang/Nim/issues/5301>`_)
- Fixed "Type inferring templates do not work with non-ref types."
  (`#4973 <https://github.com/nim-lang/Nim/issues/4973>`_)
- Fixed "Nimble package list no longer works on lib.html"
  (`#5318 <https://github.com/nim-lang/Nim/issues/5318>`_)
- Fixed "Missing file name and line number in error message"
  (`#4992 <https://github.com/nim-lang/Nim/issues/4992>`_)
- Fixed "ref type can't be converted to var parameter in VM"
  (`#5327 <https://github.com/nim-lang/Nim/issues/5327>`_)
- Fixed "nimweb ignores the value of --parallelBuild"
  (`#5328 <https://github.com/nim-lang/Nim/issues/5328>`_)
- Fixed "Cannot unregister/close AsyncEvent from within its handler"
  (`#5331 <https://github.com/nim-lang/Nim/issues/5331>`_)
- Fixed "name collision with template instanciated generic inline function with inlined iterator specialization used from different modules"
  (`#5285 <https://github.com/nim-lang/Nim/issues/5285>`_)
- Fixed "object in VM does not have value semantic"
  (`#5269 <https://github.com/nim-lang/Nim/issues/5269>`_)
- Fixed "Unstable tuple destructuring behavior in Nim VM"
  (`#5221 <https://github.com/nim-lang/Nim/issues/5221>`_)
- Fixed "nre module breaks os templates"
  (`#4996 <https://github.com/nim-lang/Nim/issues/4996>`_)
- Fixed "Cannot implement distinct seq with setLen"
  (`#5090 <https://github.com/nim-lang/Nim/issues/5090>`_)
- Fixed "await inside array/dict literal produces invalid code"
  (`#5314 <https://github.com/nim-lang/Nim/issues/5314>`_)

- Fixed "asyncdispatch.accept() can raise exception inside poll() instead of failing future on Windows"
  (`#5279 <https://github.com/nim-lang/Nim/issues/5279>`_)
- Fixed "VM: A crash report should be more informative"
  (`#5352 <https://github.com/nim-lang/Nim/issues/5352>`_)
- Fixed "IO routines are poor at handling errors"
  (`#5349 <https://github.com/nim-lang/Nim/issues/5349>`_)
- Fixed "new import syntax doesn't work?"
  (`#5185 <https://github.com/nim-lang/Nim/issues/5185>`_)
- Fixed "Seq of object literals skips unmentioned fields"
  (`#5339 <https://github.com/nim-lang/Nim/issues/5339>`_)
- Fixed "``sym is not accessible`` in compile time"
  (`#5354 <https://github.com/nim-lang/Nim/issues/5354>`_)
- Fixed "the matching is broken in re.nim"
  (`#5382 <https://github.com/nim-lang/Nim/issues/5382>`_)
- Fixed "development branch breaks in my c wrapper"
  (`#5392 <https://github.com/nim-lang/Nim/issues/5392>`_)
- Fixed "Bad codegen: toSeq + tuples + generics"
  (`#5383 <https://github.com/nim-lang/Nim/issues/5383>`_)
- Fixed "Bad codegen: toSeq + tuples + generics"
  (`#5383 <https://github.com/nim-lang/Nim/issues/5383>`_)
- Fixed "Codegen error when using container of containers"
  (`#5402 <https://github.com/nim-lang/Nim/issues/5402>`_)
- Fixed "sizeof(RangeType) is not available in static context"
  (`#5399 <https://github.com/nim-lang/Nim/issues/5399>`_)
- Fixed "Regression: ICE: expr: var not init ex_263713"
  (`#5405 <https://github.com/nim-lang/Nim/issues/5405>`_)
- Fixed "Stack trace is wrong when assignment operator fails with template"
  (`#5400 <https://github.com/nim-lang/Nim/issues/5400>`_)
- Fixed "SIGSEGV in compiler"
  (`#5391 <https://github.com/nim-lang/Nim/issues/5391>`_)
- Fixed "Compiler regression with struct member names"
  (`#5404 <https://github.com/nim-lang/Nim/issues/5404>`_)
- Fixed "Regression: compiler segfault"
  (`#5419 <https://github.com/nim-lang/Nim/issues/5419>`_)
- Fixed "The compilation of jester routes is broken on devel"
  (`#5417 <https://github.com/nim-lang/Nim/issues/5417>`_)
- Fixed "Non-generic return type produces "method is not a base""
  (`#5432 <https://github.com/nim-lang/Nim/issues/5432>`_)
- Fixed "Confusing error behavior when calling slice[T].random"
  (`#5430 <https://github.com/nim-lang/Nim/issues/5430>`_)
- Fixed "Wrong method called"
  (`#5439 <https://github.com/nim-lang/Nim/issues/5439>`_)
- Fixed "Attempt to document the strscans.scansp macro"
  (`#5154 <https://github.com/nim-lang/Nim/issues/5154>`_)
- Fixed "[Regression] Invalid C code for _ symbol inside jester routes"
  (`#5452 <https://github.com/nim-lang/Nim/issues/5452>`_)
- Fixed "StdLib base64 encodeInternal crashes with out of bound exception"
  (`#5457 <https://github.com/nim-lang/Nim/issues/5457>`_)
- Fixed "Nim hangs forever in infinite loop in nre library"
  (`#5444 <https://github.com/nim-lang/Nim/issues/5444>`_)

- Fixed "Tester passes test although individual test in suite fails"
  (`#5472 <https://github.com/nim-lang/Nim/issues/5472>`_)
- Fixed "terminal.nim documentation"
  (`#5483 <https://github.com/nim-lang/Nim/issues/5483>`_)
- Fixed "Codegen error - expected identifier before ')' token (probably regression)"
  (`#5481 <https://github.com/nim-lang/Nim/issues/5481>`_)
- Fixed "mixin not works inside generic proc generated by template"
  (`#5478 <https://github.com/nim-lang/Nim/issues/5478>`_)
- Fixed "var not init (converter + template + macro)"
  (`#5467 <https://github.com/nim-lang/Nim/issues/5467>`_)
- Fixed "`==` for OrderedTable should consider equal content but different size as equal."
  (`#5487 <https://github.com/nim-lang/Nim/issues/5487>`_)
- Fixed "Fixed tests/tester.nim"
  (`#45 <https://github.com/nim-lang/Nim/issues/45>`_)
- Fixed "template instanciation crashes compiler"
  (`#5428 <https://github.com/nim-lang/Nim/issues/5428>`_)
- Fixed "Internal compiler error in handleGenericInvocation"
  (`#5167 <https://github.com/nim-lang/Nim/issues/5167>`_)
- Fixed "compiler crash in forwarding template"
  (`#5455 <https://github.com/nim-lang/Nim/issues/5455>`_)
- Fixed "Doc query re public/private + suggestion re deprecated"
  (`#5529 <https://github.com/nim-lang/Nim/issues/5529>`_)
- Fixed "inheritance not work for generic object whose parent is parameterized"
  (`#5264 <https://github.com/nim-lang/Nim/issues/5264>`_)
- Fixed "weird inheritance rule restriction"
  (`#5231 <https://github.com/nim-lang/Nim/issues/5231>`_)
- Fixed "Enum with holes broken in JS"
  (`#5062 <https://github.com/nim-lang/Nim/issues/5062>`_)
- Fixed "enum type and aliased enum type inequality when tested with operator `is` involving template"
  (`#5360 <https://github.com/nim-lang/Nim/issues/5360>`_)
- Fixed "logging: problem with console logger caused by the latest changes in sysio"
  (`#5546 <https://github.com/nim-lang/Nim/issues/5546>`_)
- Fixed "Crash if proc and caller doesn't define seq type - HEAD"
  (`#4756 <https://github.com/nim-lang/Nim/issues/4756>`_)
- Fixed "`path` config option doesn't work when compilation is invoked from a different directory"
  (`#5228 <https://github.com/nim-lang/Nim/issues/5228>`_)
- Fixed "segfaults module doesn't compile with C++ backend"
  (`#5550 <https://github.com/nim-lang/Nim/issues/5550>`_)
- Fixed "Improve `joinThreads` for windows"
  (`#4972 <https://github.com/nim-lang/Nim/issues/4972>`_)
- Fixed "Compiling in release mode prevents valid code execution."
  (`#5296 <https://github.com/nim-lang/Nim/issues/5296>`_)
- Fixed "Forward declaration of generic procs or iterators doesn't work"
  (`#4104 <https://github.com/nim-lang/Nim/issues/4104>`_)
- Fixed "cant create thread after join"
  (`#4719 <https://github.com/nim-lang/Nim/issues/4719>`_)
- Fixed "can't compile with var name "near" and --threads:on"
  (`#5598 <https://github.com/nim-lang/Nim/issues/5598>`_)
- Fixed "inconsistent behavior when calling parent's proc of generic object"
  (`#5241 <https://github.com/nim-lang/Nim/issues/5241>`_)
- Fixed "The problem with import order of asyncdispatch and unittest modules"
  (`#5597 <https://github.com/nim-lang/Nim/issues/5597>`_)
- Fixed "Generic code fails to compile in unexpected ways"
  (`#976 <https://github.com/nim-lang/Nim/issues/976>`_)
- Fixed "Another 'User defined type class' issue"
  (`#1128 <https://github.com/nim-lang/Nim/issues/1128>`_)
- Fixed "compiler fails to compile user defined typeclass"
  (`#1147 <https://github.com/nim-lang/Nim/issues/1147>`_)
- Fixed "Type class membership testing doesn't work on instances of generic object types"
  (`#1570 <https://github.com/nim-lang/Nim/issues/1570>`_)
- Fixed "Strange overload resolution behavior for procedures with typeclass arguments"
  (`#1991 <https://github.com/nim-lang/Nim/issues/1991>`_)
- Fixed "The same UDTC can't constrain two type parameters in the same procedure"
  (`#2018 <https://github.com/nim-lang/Nim/issues/2018>`_)
- Fixed "More trait/concept issues"
  (`#2423 <https://github.com/nim-lang/Nim/issues/2423>`_)
- Fixed "Bugs with concepts?"
  (`#2882 <https://github.com/nim-lang/Nim/issues/2882>`_)