Version 0.8.12 released
==================================

.. container:: metadata

  Posted by Andreas Rumpf on 10/07/2011

Bugfixes
--------

- Bugfix: ``httpclient`` correct passes the path starting with ``/``.
- Bugfixes for the ``htmlparser`` module.
- Bugfix: ``pegs.find`` did not respect ``start`` parameter.
- Bugfix: ``dialogs.ChooseFilesToOpen`` did not work if only one file is
  selected.
- Bugfix: niminst: ``nimrod`` is not default dir for *every* project.
- Bugfix: Multiple yield statements in iterators did not cause local vars to be
  copied.
- Bugfix: The compiler does not emit very inaccurate floating point literals
  anymore.
- Bugfix: Subclasses are taken into account for ``try except`` matching.
- Bugfix: Generics and macros are more stable. There are still known bugs left
  though.
- Bugfix: Generated type information for tuples was sometimes wrong, causing
  random crashes.
- Lots of other bugfixes: Too many to list them all.


Changes affecting backwards compatibility
-----------------------------------------

- Operators starting with ``^`` are now right-associative and have the highest
  priority.
- Deprecated ``os.getApplicationFilename``: Use ``os.getAppFilename`` instead.
- Deprecated ``os.getApplicationDir``: Use ``os.getAppDir`` instead.
- Deprecated ``system.copy``: Use ``substr`` or string slicing instead.
- Changed and documented how generalized string literals work: The syntax
  ``module.re"abc"`` is now supported.
- Changed the behaviour of ``strutils.%``, ``ropes.%``
  if both notations ``$#`` and ``$i`` are involved.
- The ``pegs`` and ``re`` modules distinguish between ``replace``
  and ``replacef`` operations.
- The pointer dereference operation ``p^`` is deprecated and might become
  ``^p`` in later versions or be dropped entirely since it is rarely used.
  Use the new notation ``p[]`` in the rare cases where you need to
  dereference a pointer explicitly.
- ``system.readFile`` does not return ``nil`` anymore but raises an ``EIO``
  exception instead.
- Unsound co-/contravariance for procvars has been removed.


Language Additions
------------------

- Source code filters are now documented.
- Added the ``linearScanEnd``, ``unroll``, ``shallow`` pragmas.
- Added ``emit`` pragma for direct code generator control.
- Case statement branches support constant sets for programming convenience.
- Tuple unpacking is not enforced in ``for`` loops anymore.
- The compiler now supports array, sequence and string slicing.
- A field in an ``enum`` may be given an explicit string representation.
  This yields more maintainable code than using a constant
  ``array[TMyEnum, string]`` mapping.
- Indices in array literals may be explicitly given, enhancing readability:
  ``[enumValueA: "a", enumValueB: "b"]``.
- Added thread support via the ``threads`` core module and
  the ``--threads:on`` command line switch.
- The built-in iterators ``system.fields`` and ``system.fieldPairs`` can be
  used to iterate over any field of a tuple. With this mechanism operations
  like ``==`` and ``hash`` are lifted to tuples.
- The slice ``..`` is now a first-class operator, allowing code like:
  ``x in 1000..100_000``.


Compiler Additions
------------------

- The compiler supports IDEs via the new group of ``idetools`` command line
  options.
- The *interactive mode* (REPL) has been improved and documented for the
  first time.
- The compiler now might use hashing for string case statements depending
  on the number of string literals in the case statement.


Library Additions
-----------------

- Added ``lists`` module which contains generic linked lists.
- Added ``sets`` module which contains generic hash sets.
- Added ``tables`` module which contains generic hash tables.
- Added ``queues`` module which contains generic sequence based queues.
- Added ``intsets`` module which contains a specialized int set data type.
- Added ``scgi`` module.
- Added ``smtp`` module.
- Added ``encodings`` module.
- Added ``re.findAll``, ``pegs.findAll``.
- Added ``os.findExe``.
- Added ``parseutils.parseUntil`` and ``parseutils.parseWhile``.
- Added ``strutils.align``, ``strutils.tokenize``, ``strutils.wordWrap``.
- Pegs support a *captured search loop operator* ``{@}``.
- Pegs support new built-ins: ``\letter``, ``\upper``, ``\lower``,
  ``\title``, ``\white``.
- Pegs support the new built-in ``\skip`` operation.
- Pegs support the ``$`` and ``^`` anchors.
- Additional operations were added to the ``complex`` module.
- Added ``strutils.formatFloat``,  ``strutils.formatBiggestFloat``.
- Added unary ``<`` for nice looking excluding upper bounds in ranges.
- Added ``math.floor``.
- Added ``system.reset`` and a version of ``system.open`` that
  returns a ``TFile`` and raises an exception in case of an error.
- Added a wrapper for ``redis``.
- Added a wrapper for ``0mq`` via the ``zmq`` module.
- Added a wrapper for ``sphinx``.
- Added ``system.newStringOfCap``.
- Added ``system.raiseHook`` and ``system.outOfMemHook``.
- Added ``system.writeFile``.
- Added ``system.shallowCopy``.
- ``system.echo`` is guaranteed to be thread-safe.
- Added ``prelude`` include file for scripting convenience.
- Added ``typeinfo`` core module for access to runtime type information.
- Added ``marshal`` module for JSON serialization.
