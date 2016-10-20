Version 0.10.2 released
=======================

.. container:: metadata

  Posted by Dominik Picheta on 29/12/2014

This release marks the completion of a very important change to the project:
the official renaming from Nimrod to Nim. Version 0.10.2 contains many language
changes, some of which may break your existing code. For your convenience, we
added a new tool called `nimfix <nimfix.html>`_ that will help you convert your
existing projects so that it works with the latest version of the compiler.

Progress towards version 1.0
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Although Nim is still pre-1.0, we were able to keep the number of breaking
changes to a minimum so far. Starting with version 1.0, we will not introduce
any breaking changes between major release versions.
One of Nim's goals is to ensure that the compiler is as efficient as possible.
Take a look at the
`latest benchmarks <https://github.com/logicchains/LPATHBench/blob/master/writeup.md>`_,
which show that Nim is consistently near
the top and already nearly as fast as C and C++. Recent developments, such as
the new ``asyncdispatch`` module will allow you to write efficient web server
applications using non-blocking code. Nim now also has a built-in thread pool
for lightweight threading through the use of ``spawn``.

The unpopular "T" and "P" prefixes on types have been deprecated. Nim also
became more expressive by weakening the distinction between statements and
expressions. We also added a new and searchable forum, a new website, and our
documentation generator ``docgen`` has seen major improvements. Many thanks to
Nick Greenfield for the much more beautiful documentation!



What's left to be done
~~~~~~~~~~~~~~~~~~~~~~

The 1.0 release is actually very close. Apart from bug fixes, there are
two major features missing or incomplete:

* ``static[T]`` needs to be defined precisely and the bugs in the
  implementation need to be fixed.
* Overloading of the assignment operator is required for some generic
  containers and needs to be implemented.

This means that fancy matrix libraries will finally start to work, which used
to be a major point of pain in the language.


Nimble and other Nim tools
~~~~~~~~~~~~~~~~~~~~~~~~~~

Outside of the language and the compiler itself many Nim tools have seen
considerable improvements.

Babel the Nim package manager has been renamed to Nimble. Nimble's purpose
is the installation of packages containing libraries and/or applications
written in Nim.
Even though Nimble is still very young it already is very
functional. It can install packages by name, it does so by accessing a
packages repository which is hosted on a GitHub repo. Packages can also be
installed via a Git repo URL or Mercurial repo URL. The package repository
is searchable through Nimble. Anyone is free to add their own packages to
the package repository by forking the
`nim-lang/packages <https://github.com/nim-lang/packages>`_ repo and creating
a pull request. Nimble is fully cross-platform and should be fully functional
on all major operating systems.
It is of course completely written in Nim.

Changelog
~~~~~~~~~

Changes affecting backwards compatibility
-----------------------------------------

- **The language has been renamed from Nimrod to Nim.** The name of the
  compiler changed from ``nimrod`` to ``nim`` too.
- ``system.fileHandle`` has been renamed to ``system.getFileHandle`` to
  prevent name conflicts with the new type ``FileHandle``.
- Comments are now not part of the AST anymore, as such you cannot use them
  in place of ``discard``.
- Large parts of the stdlib got rid of the T/P type prefixes. Instead most
  types now simply start with an uppercased letter. The
  so called "partial case sensitivity" rule is now active allowing for code
  like ``var foo: Foo`` in more contexts.
- String case (or any non-ordinal case) statements
  without 'else' are deprecated.
- Recursive tuple types are not allowed anymore. Use ``object`` instead.
- The PEGS module returns ``nil`` instead of ``""`` when an optional capture
  fails to match.
- The re module returns ``nil`` instead of ``""`` when an optional capture
  fails to match.
- The "symmetric set difference" operator (``-+-``) never worked and has been
  removed.
- ``defer`` is a keyword now.
- ``func`` is a keyword now.
- The ``using`` language feature now needs to be activated via the new
  ``{.experimental.}`` pragma that enables experimental language features.
- Destructors are now officially *experimental*.
- Standalone ``except`` and ``finally`` statements are deprecated now.
  The standalone ``finally`` can be replaced with ``defer``,
  standalone ``except`` requires an explicit ``try``.
- Operators ending in ``>`` are considered as "arrow like" and have their
  own priority level and are right associative. This means that
  the ``=>`` and ``->`` operators from the `future <future.html>`_ module
  work better.
- Field names in tuples are now ignored for type comparisons. This allows
  for greater interoperability between different modules.
- Statement lists are not converted to an implicit ``do`` block anymore. This
  means the confusing ``nnkDo`` nodes when working with macros are gone for
  good.


Language Additions
------------------

- The new concurrency model has been implemented including ``locks`` sections,
  lock levels and object field ``guards``.
- The ``parallel`` statement has been implemented.
- ``deepCopy`` has been added to the language.
- The builtin ``procCall`` can be used to get ``super``-like functionality
  for multi methods.
- There is a new pragma ``{.experimental.}`` that enables experimental
  language features per module, or you can enable these features on a global
  level with the ``--experimental`` command line option.


Compiler Additions
------------------

- The compiler now supports *mixed* Objective C / C++ / C code generation:
  The modules that use ``importCpp`` or ``importObjc`` are compiled to C++
  or Objective C code, any other module is compiled to C code. This
  improves interoperability.
- There is a new ``parallel`` statement for safe fork&join parallel computing.
- ``guard`` and ``lock`` pragmas have been implemented to support safer
  concurrent programming.
- The following procs are now available at compile-time::

    math.sqrt, math.ln, math.log10, math.log2, math.exp, math.round,
    math.arccos, math.arcsin, math.arctan, math.arctan2, math.cos,
    math.cosh, math.hypot, math.sinh, math.sin, math.tan, math.tanh,
    math.pow, math.trunc, math.floor, math.ceil, math.fmod,
    os.getEnv, os.existsEnv, os.dirExists, os.fileExists,
    system.writeFile

- Two backticks now produce a single backtick within an ``emit`` or ``asm``
  statement.
- There is a new tool, `nimfix <nimfix.html>`_ to help you in updating your
  code from Nimrod to Nim.
- The compiler's output has been prettified.

Library Additions
-----------------

- Added module ``fenv`` to control the handling of floating-point rounding and
  exceptions (overflow, division by zero, etc.).
- ``system.setupForeignThreadGc`` can be used for better interaction with
  foreign libraries that create threads and run a Nim callback from these
  foreign threads.
- List comprehensions have been implemented as a macro in the ``future``
  module.
- The new Async module (``asyncnet``) now supports SSL.
- The ``smtp`` module now has an async implementation.
- Added module ``asyncfile`` which implements asynchronous file reading
  and writing.
- ``osproc.kill`` has been added.
- ``asyncnet`` and ``asynchttpserver`` now support ``SO_REUSEADDR``.

Bugfixes
--------

- ``nil`` and ``NULL`` are now preserved between Nim and databases in the
  ``db_*`` modules.
- Fixed issue with OS module in non-unicode mode on Windows.
- Fixed issue with ``x.low``
  (`#1366 <https://github.com/Araq/Nim/issues/1366>`_).
- Fixed tuple unpacking issue inside closure iterators
  (`#1067 <https://github.com/Araq/Nim/issues/1067>`_).
- Fixed ENDB compilation issues.
- Many ``asynchttpserver`` fixes.
- Macros can now keep global state across macro calls
  (`#903 <https://github.com/Araq/Nim/issues/903>`_).
- ``osproc`` fixes on Windows.
- ``osproc.terminate`` fixed.
- Improvements to exception handling in async procedures.
  (`#1487 <https://github.com/Araq/Nim/issues/1487>`_).
- ``try`` now works at compile-time.
- Fixes ``T = ref T`` to be an illegal recursive type.
- Self imports are now disallowed.
- Improved effect inference.
- Fixes for the ``math`` module on Windows.
- User defined pragmas will now work for generics that have
  been instantiated in different modules.
- Fixed queue exhaustion bug.
- Many, many more.
