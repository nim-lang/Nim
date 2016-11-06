Version 0.9.0 released
======================

.. container:: metadata

  Posted by Andreas Rumpf on 23/09/2012

Summary
-------

* Unsigned integers have been added.
* The integer type promotion rules changed.
* The template and macro system evolved.
* Closures have been implemented.
* Term rewriting macros have been implemented.
* First steps to unify expressions and statements have been taken.
* Symbol lookup rules in generics have become stricter to catch more errors.


Bugfixes
--------

- Fixed a bug where the compiler would "optimize away" valid constant parts of
  a string concatenation.
- Fixed a bug concerning implicit type conversions in ``case`` statements.
- Fixed a serious code generation bug that caused ``algorithm.sort`` to
  produce segmentation faults.
- Fixed ambiguity in recvLine which meant that receiving ``\r\L`` was
  indistinguishable from disconnections.
- Many more bugfixes, too many to list them all.


Library Additions
-----------------

- Added the (already existing) module ``htmlgen`` to the documentation.
- Added the (already existing) module ``cookies`` to the documentation.
- Added ``system.shallow`` that can be used to speed up string and sequence
  assignments.
- Added ``system.eval`` that can execute an anonymous block of code at
  compile time as if was a macro.
- Added ``system.staticExec`` and ``system.gorge`` for compile-time execution
  of external programs.
- Added ``system.staticRead`` as a synonym for ``system.slurp``.
- Added ``macros.emit`` that can emit an arbitrary computed string as nimrod
  code during compilation.
- Added ``strutils.parseEnum``.
- Added ``json.%`` constructor operator.
- The stdlib can now be avoided to a point where C code generation for 16bit
  micro controllers is feasible.
- Added module ``oids``.
- Added module ``endians``.
- Added a new OpenGL wrapper that supports OpenGL up to version 4.2.
- Added a wrapper for ``libsvm``.
- Added a wrapper for ``mongodb``.
- Added ``terminal.isatty``.
- Added an overload for ``system.items`` that can be used to iterate over the
  values of an enum.
- Added ``system.TInteger`` and ``system.TNumber`` type classes matching
  any of the corresponding types available in Nimrod.
- Added ``system.clamp`` to limit a value within an interval ``[a, b]``.
- Added ``strutils.continuesWith``.
- Added ``system.getStackTrace``.
- Added ``system.||`` for parallel ``for`` loop support.
- The GC supports (soft) realtime systems via ``GC_setMaxPause``
  and ``GC_step`` procs.
- The sockets module now supports ssl through the OpenSSL library, ``recvLine``
  is now much more efficient thanks to the newly implemented sockets buffering.
- The httpclient module now supports ssl/tls.
- Added ``times.format`` as well as many other utility functions
  for managing time.
- Added ``system.@`` for converting an ``openarray`` to a ``seq`` (it used to
  only support fixed length arrays).
- Added ``system.compiles`` which can be used to check whether a type supports
  some operation.
- Added ``strutils.format``, ``subexes.format`` which use the
  new ``varargs`` type.
- Added module ``fsmonitor``.

Changes affecting backwards compatibility
-----------------------------------------

- On Windows filenames and paths are supposed to be in UTF-8.
  The ``system``, ``os``, ``osproc`` and ``memfiles`` modules use the wide
  string versions of the WinAPI. Use the ``-d:useWinAnsi`` switch to revert
  back to the old behaviour which uses the Ansi string versions.
- ``static``, ``do``, ``interface`` and ``mixin`` are now keywords.
- Templates now participate in overloading resolution which can break code that
  uses templates in subtle ways. Use the new ``immediate`` pragma for templates
  to get a template of old behaviour.
- There is now a proper distinction in the type system between ``expr`` and
  ``PNimrodNode`` which unfortunately breaks the old macro system.
- ``pegs.@`` has been renamed to ``pegs.!*`` and ``pegs.@@`` has been renamed
  to ``pegs.!*\`` as ``@`` operators now have different precedence.
- The type ``proc`` (without any params or return type) is now considered a
  type class matching all proc types. Use ``proc ()`` to get the old meaning
  denoting a proc expecing no arguments and returing no value.
- Deprecated ``system.GC_setStrategy``.
- ``re.findAll`` and ``pegs.findAll`` don't return *captures* anymore but
  matching *substrings*.
- RTTI and thus the ``marshall`` module don't contain the proper field names
  of tuples anymore. This had to be changed as the old behaviour never
  produced consistent results.
- Deprecated the ``ssl`` module.
- Deprecated ``nimrod pretty`` as it never worked good enough and has some
  inherent problems.
- The integer promotion rules changed; the compiler is now less picky in some
  situations and more picky in other situations: In particular implicit
  conversions from ``int`` to ``int32`` are now forbidden.
- ``system.byte`` is now an alias for ``uint8``; it used to be an alias
  to ``int8``.
- ``bind`` expressions in templates are not properly supported anymore. Use
  the declarative ``bind`` statement instead.
- The default calling convention for a procedural **type** is now ``closure``,
  for procs it remains ``nimcall`` (which is compatible to ``closure``).
  Activate the warning ``ImplicitClosure`` to make the compiler list the
  occurrences of proc types which are affected.
- The Nimrod type system now distinguishes ``openarray`` from ``varargs``.
- Templates are now ``hygienic``. Use the ``dirty`` pragma to get the old
  behaviour.
- Objects that have no ancestor are now implicitly ``final``. Use
  the ``inheritable`` pragma to introduce new object roots apart
  from ``TObject``.
- Macros now receive parameters like templates do; use the ``callsite`` builtin
  to gain access to the invocation AST.
- Symbol lookup rules in generics have become stricter to catch more errors.


Compiler Additions
------------------

- Win64 is now an officially supported target.
- The Nimrod compiler works on BSD again, but has some issues
  as ``os.getAppFilename`` and ``os.getAppDir`` cannot work reliably on BSD.
- The compiler can detect and evaluate calls that can be evaluated at compile
  time for optimization purposes with the ``--implicitStatic`` command line
  option or pragma.
- The compiler now generates marker procs that the GC can use instead of RTTI.
  This speeds up the GC quite a bit.
- The compiler now includes a new advanced documentation generator
  via the ``doc2`` command. This new generator uses all of the semantic passes
  of the compiler and can thus generate documentation for symbols hiding in
  macros.
- The compiler now supports the ``dynlib`` pragma for variables.
- The compiler now supports ``bycopy`` and ``byref`` pragmas that affect how
  objects/tuples are passed.
- The embedded profiler became a stack trace profiler and has been documented.


Language Additions
------------------

- Added explicit ``static`` sections for enforced compile time evaluation.
- Added an alternative notation for lambdas with ``do``.
- ``addr`` is now treated like a prefix operator syntactically.
- Added ``global`` pragma that can be used to introduce new global variables
  from within procs.
- ``when`` expressions are now allowed just like ``if`` expressions.
- The precedence for operators starting with ``@`` is different now
  allowing for *sigil-like* operators.
- Stand-alone ``finally`` and ``except`` blocks are now supported.
- Macros and templates can now be invoked as pragmas.
- The apostrophe in type suffixes for numerical literals is now optional.
- Unsigned integer types have been added.
- The integer promotion rules changed.
- Nimrod now tracks proper intervals for ``range`` over some built-in operators.
- In parameter lists a semicolon instead of a comma can be used to improve
  readability: ``proc divmod(a, b: int; resA, resB: var int)``.
- A semicolon can now be used to have multiple simple statements on a single
  line: ``inc i; inc j``.
- ``bind`` supports overloaded symbols and operators.
- A ``distinct`` type can now borrow from generic procs.
- Added the pragmas ``gensym``, ``inject`` and ``dirty`` for hygiene
  in templates.
- Comments can be continued with a backslash continuation character so that
  comment pieces don't have to align on the same column.
- Enums can be annotated with ``pure`` so that their field names do not pollute
  the current scope.
- A proc body can consist of an expression that has a type. This is rewritten
  to ``result = expression`` then.
- Term rewriting macros (see `trmacros <http://nimrod-code.org/trmacros.html>`_)
  have been implemented but are still in alpha.
