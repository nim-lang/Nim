2012-02-09 Version 0.8.14 released
==================================

.. container:: metadata

  Posted by Andreas Rumpf on 09/02/2012

Version 0.8.14 has been released!

Bugfixes
--------

- Fixed a serious memory corruption concerning message passing.
- Fixed a serious bug concerning different instantiations of a generic proc.
- Fixed a newly introduced bug where a wrong ``EIO`` exception was raised for
  the end of file for text files that do not end with a newline.
- Bugfix c2nim, c2pas: the ``--out`` option has never worked properly.
- Bugfix: forwarding of generic procs never worked.
- Some more bugfixes for macros and compile-time evaluation.
- The GC now takes into account interior pointers on the stack which may be
  introduced by aggressive C optimizers.
- Nimrod's native allocator/GC now works on PowerPC.
- Lots of other bugfixes: Too many to list them all.


Changes affecting backwards compatibility
-----------------------------------------

- Removed deprecated ``os.AppendFileExt``, ``os.executeShellCommand``,
  ``os.iterOverEnvironment``, ``os.pcDirectory``, ``os.pcLinkToDirectory``,
  ``os.SplitPath``, ``os.extractDir``, ``os.SplitFilename``,
  ``os.extractFileTrunk``, ``os.extractFileExt``, ``osproc.executeProcess``,
  ``osproc.executeCommand``.
- Removed deprecated ``parseopt.init``, ``parseopt.getRestOfCommandLine``.
- Moved ``strutils.validEmailAddress`` to ``matchers.validEmailAddress``.
- The pointer dereference operator ``^`` has been removed, so that ``^``
  can now be a user-defined operator.
- ``implies`` is no keyword anymore.
- The ``is`` operator is now the ``of`` operator.
- The ``is`` operator is now used to check type equivalence in generic code.
- The ``pure`` pragma for procs has been renamed to ``noStackFrame``.
- The threading API has been completely redesigned.
- The ``unidecode`` module is now thread-safe and its interface has changed.
- The ``bind`` expression is deprecated, use a ``bind`` declaration instead.
- ``system.raiseHook`` is now split into ``system.localRaiseHook`` and
  ``system.globalRaiseHook`` to distinguish between thread local and global
  raise hooks.
- Changed exception handling/error reporting for ``os.removeFile`` and
  ``os.removeDir``.
- The algorithm for searching and loading configuration files has been changed.
- Operators now have diffent precedence rules: Assignment-like operators
  (like ``*=``) are now special-cased.
- The fields in ``TStream`` have been renamed to have an ``Impl`` suffix
  because they should not be used directly anymore.
  Wrapper procs have been created that should be used instead.
- ``export`` is now a keyword.
- ``assert`` is now implemented in pure Nimrod as a template; it's easy
  to implement your own assertion templates with ``system.astToStr``.


Language Additions
------------------

- Added new ``is`` and ``of`` operators.
- The built-in type ``void`` can be used to denote the absence of any type.
  This is useful in generic code.
- Return types may be of the type ``var T`` to return an l-value.
- The error pragma can now be used to mark symbols whose *usage* should trigger
  a compile-time error.
- There is a new ``discardable`` pragma that can be used to mark a routine
  so that its result can be discarded implicitly.
- Added a new ``noinit`` pragma to prevent automatic initialization to zero
  of variables.
- Constants can now have the type ``seq``.
- There is a new user-definable syntactic construct ``a{i, ...}``
  that has no semantics yet for built-in types and so can be overloaded to your
  heart's content.
- ``bind`` (used for symbol binding in templates and generics) is now a
  declarative statement.
- Nimrod now supports single assignment variables via the ``let`` statement.
- Iterators named ``items`` and ``pairs`` are implicitly invoked when
  an explicit iterator is missing.
- The slice assignment ``a[i..j] = b`` where ``a`` is a sequence or string
  now supports *splicing*.


Compiler Additions
------------------

- The compiler can generate C++ code for easier interfacing with C++.
- The compiler can generate Objective C code for easier interfacing with
  Objective C.
- The new pragmas ``importcpp`` and ``importobjc`` make interfacing with C++
  and Objective C somewhat easier.
- Added a new pragma ``incompleteStruct`` to deal with incomplete C struct
  definitions.
- Added a ``--nimcache:PATH`` configuration option for control over the output
  directory for generated code.
- The ``--genScript`` option now produces different compilation scripts
  which do not contain absolute paths.
- Added ``--cincludes:dir``, ``--clibdir:lib`` configuration options for
  modifying the C compiler's header/library search path in cross-platform way.
- Added ``--clib:lib`` configuration option for specifying additional
  C libraries to be linked.
- Added ``--mainmodule:file`` configuration options for specifying the main
  project file. This is intended to be used in project configuration files to
  allow commands like ``nimrod c`` or ``nimrod check`` to be executed anywhere
  within the project's directory structure.
- Added a ``--app:staticlib`` option for creating static libraries.
- Added a ``--tlsEmulation:on|off`` switch for control over thread local
  storage emulation.
- The compiler and standard library now support a *taint mode*. Input strings
  are declared with the ``TaintedString`` string type. If the taint
  mode is turned on it is a distinct string type which helps to detect input
  validation errors.
- The compiler now supports the compilation cache via ``--symbolFiles:on``.
  This potentially speeds up compilations by an order of magnitude, but is
  still highly experimental!
- Added ``--import:file`` and ``--include:file`` configuration options
  for specifying modules that will be automatically imported/incluced.
- ``nimrod i`` can now optionally be given a module to execute.
- The compiler now performs a simple alias analysis to generate better code.
- The compiler and ENDB now support *watchpoints*.
- The compiler now supports proper compile time expressions of type ``bool``
  for ``on|off`` switches in pragmas. In order to not break existing code,
  ``on`` and ``off`` are now aliases for ``true`` and ``false`` and declared
  in the system module.
- The compiler finally supports **closures**. This is a preliminary
  implementation, which does not yet support nestings deeper than 1 level
  and still has many known bugs.


Library Additions
-----------------

- Added ``system.allocShared``, ``system.allocShared0``,
  ``system.deallocShared``, ``system.reallocShared``.
- Slicing as implemented by the system module now supports *splicing*.
- Added explicit channels for thread communication.
- Added ``matchers`` module for email address etc. matching.
- Added ``strutils.unindent``, ``strutils.countLines``,
  ``strutils.replaceWord``.
- Added ``system.slurp`` for easy resource embedding.
- Added ``system.running`` for threads.
- Added ``system.programResult``.
- Added ``xmltree.innerText``.
- Added ``os.isAbsolute``, ``os.dynLibFormat``, ``os.isRootDir``,
  ``os.parentDirs``.
- Added ``parseutils.interpolatedFragments``.
- Added ``macros.treeRepr``, ``macros.lispRepr``, ``macros.dumpTree``,
  ``macros.dumpLisp``, ``macros.parseExpr``, ``macros.parseStmt``,
  ``macros.getAst``.
- Added ``locks`` core module for more flexible locking support.
- Added ``irc`` module.
- Added ``ftpclient`` module.
- Added ``memfiles`` module.
- Added ``subexes`` module.
- Added ``critbits`` module.
- Added ``asyncio`` module.
- Added ``actors`` module.
- Added ``algorithm`` module for generic ``sort``, ``reverse`` etc. operations.
- Added ``osproc.startCmd``, ``osproc.execCmdEx``.
- The ``osproc`` module now uses ``posix_spawn`` instead of ``fork``
  and ``exec`` on Posix systems. Define the symbol ``useFork`` to revert to
  the old implementation.
- Added ``intsets.assign``.
- Added ``system.astToStr`` and ``system.rand``, ``system.doAssert``.
- Added ``system.pairs`` for built-in types like arrays and strings.
