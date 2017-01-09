Version 0.16.0 released
=======================

.. container:: metadata

  Posted by The Nim Team on 08/01/2017

We're happy to announce that the latest release of Nim, version 0.16.0, is now
available!

As always, you can grab the latest version from the
`downloads page <http://nim-lang.org/download.html>`_.

This release includes over 80 bug fixes and improvements. To see a full list
of changes, take a look at the detailed changelog
`below <#changelog>`_.

Some of the most significant changes in this release include: a major new
Nimble release, an improved import syntax, and the stabilisation of
name mangling rules enabling faster compile times.

The new Nimble release that is included with Nim 0.16.0 includes a variety of
new features and bug fixes. The most prominent of which is the improved output
system, as shown in the figure below.

.. raw::html

  <a href="../assets/news/images/0.16.0/nimble.png">
    <img src="../assets/news/images/0.16.0/nimble.png" alt="Nimble 0.8.0" style="width:100%"/>
  </a>

For a full list of changes in Nimble, see its
`changelog <https://github.com/nim-lang/nimble/blob/master/changelog.markdown#080---05012017>`_.

The new import syntax makes it easier to import multiple modules from the same
package or directory. For example:

.. code-block:: nim
  import compiler/ast, compiler/parser, compiler/lexer
  import compiler / [ast, parser, lexer]

The two are equivalent, but the new latter syntax is less redundant.

Finally, the code responsible for name mangling in the generated C and C++ code
has been improved to reduce compile times. In particular, compile-time for
the common edit-compile-run cycles have been reduced.

Changelog
~~~~~~~~~

Changes affecting backwards compatibility
-----------------------------------------

- ``staticExec`` now uses the directory of the nim file that contains the
  ``staticExec`` call as the current working directory.
- ``TimeInfo.tzname`` has been removed from ``times`` module because it was
  broken. Because of this, the option ``"ZZZ"`` will no longer work in format
  strings for formatting and parsing.

Library Additions
-----------------

- Added new parameter to ``error`` proc of ``macro`` module to provide better
  error message
- Added new ``deques`` module intended to replace ``queues``.
  ``deques`` provides a superset of ``queues`` API with clear naming.
  ``queues`` module is now deprecated and will be removed in the future.

- Added ``hideCursor``, ``showCursor``, ``terminalWidth``,
  ``terminalWidthIoctl`` and ``terminalSize`` to the ``terminal``
  `(doc) <http://nim-lang.org/docs/terminal.html>`_ module.

- Added new module ``distros``
  `(doc) <http://nim-lang.org/docs/distros.html>`_  that can be used in Nimble
  packages to aid in supporting the OS's native package managers.


Tool Additions
--------------


Compiler Additions
------------------

- The C/C++ code generator has been rewritten to use stable
  name mangling rules. This means that compile times for
  edit-compile-run cycles are much reduced.


Language Additions
------------------

- The ``emit`` pragma now takes a list of Nim expressions instead
  of a single string literal. This list can easily contain non-strings
  like template parameters. This means ``emit`` works out of the
  box with templates and no new quoting rules needed to be introduced.
  The old way with backtick quoting is still supported but will be
  deprecated.

.. code-block:: nim
  type Vector* {.importcpp: "std::vector", header: "<vector>".}[T] = object

  template `[]=`*[T](v: var Vector[T], key: int, val: T) =
    {.emit: [v, "[", key, "] = ", val, ";"].}

  proc setLen*[T](v: var Vector[T]; size: int) {.importcpp: "resize", nodecl.}
  proc `[]`*[T](v: var Vector[T], key: int): T {.importcpp: "(#[#])", nodecl.}

  proc main =
    var v: Vector[float]
    v.setLen 1
    v[0] = 6.0
    echo v[0]

- The ``import`` statement now supports importing multiple modules from
  the same directory:

.. code-block:: nim
  import compiler / [ast, parser, lexer]

Is a shortcut for:

.. code-block:: nim
  import compiler / ast, compiler / parser, compiler / lexer


Bugfixes
--------

The list below has been generated based on the commits in Nim's git
repository. As such it lists only the issues which have been closed
via a commit, for a full list see
`this link on Github <https://github.com/nim-lang/Nim/issues?utf8=%E2%9C%93&q=is%3Aissue+closed%3A%222016-10-23+..+2017-01-07%22+>`_.

- Fixed "staticRead and staticExec have different working directories"
  (`#4871 <https://github.com/nim-lang/Nim/issues/4871>`_)
- Fixed "CountTable doesn't support the '==' operator"
  (`#4901 <https://github.com/nim-lang/Nim/issues/4901>`_)
- Fixed "documentation for module sequtls apply proc"
  (`#4386 <https://github.com/nim-lang/Nim/issues/4386>`_)
- Fixed "Operator `==` for CountTable does not work."
  (`#4946 <https://github.com/nim-lang/Nim/issues/4946>`_)
- Fixed "sysFatal (IndexError) with parseUri and the / operator"
  (`#4959 <https://github.com/nim-lang/Nim/issues/4959>`_)
- Fixed "initialSize parameter does not work in OrderedTableRef"
  (`#4940 <https://github.com/nim-lang/Nim/issues/4940>`_)
- Fixed "error proc from macro library could have a node parameter"
  (`#4915 <https://github.com/nim-lang/Nim/issues/4915>`_)
- Fixed "Segfault when comparing OrderedTableRef with nil"
  (`#4974 <https://github.com/nim-lang/Nim/issues/4974>`_)
- Fixed "Bad codegen when comparing isNil results"
  (`#4975 <https://github.com/nim-lang/Nim/issues/4975>`_)
- Fixed "OrderedTable cannot delete entry with empty string or 0 key"
  (`#5035 <https://github.com/nim-lang/Nim/issues/5035>`_)
- Fixed "Deleting specific keys from ordered table leaves it in invalid state."
  (`#5057 <https://github.com/nim-lang/Nim/issues/5057>`_)
- Fixed "Paths are converted to lowercase on Windows"
  (`#5076 <https://github.com/nim-lang/Nim/issues/5076>`_)
- Fixed "toTime(getGMTime(...)) doesn't work correctly when local timezone is not UTC"
  (`#5065 <https://github.com/nim-lang/Nim/issues/5065>`_)
- Fixed "out of memory error from `test=` type proc call when parameter is a call to a table's `[]` proc"
  (`#5079 <https://github.com/nim-lang/Nim/issues/5079>`_)
- Fixed "Incorrect field order in object construction"
  (`#5055 <https://github.com/nim-lang/Nim/issues/5055>`_)
- Fixed "Incorrect codegen when importing nre with C++ backend (commit 8494338)"
  (`#5081 <https://github.com/nim-lang/Nim/issues/5081>`_)
- Fixed "Templates, {.emit.}, and backtick interpolation do not work together"
  (`#4730 <https://github.com/nim-lang/Nim/issues/4730>`_)
- Fixed "Regression: getType fails in certain cases"
  (`#5129 <https://github.com/nim-lang/Nim/issues/5129>`_)
- Fixed "CreateThread doesn't accept functions with generics"
  (`#43 <https://github.com/nim-lang/Nim/issues/43>`_)
- Fixed "No instantiation information when template has error"
  (`#4308 <https://github.com/nim-lang/Nim/issues/4308>`_)
- Fixed "realloc leaks"
  (`#4818 <https://github.com/nim-lang/Nim/issues/4818>`_)
- Fixed "Regression: getType"
  (`#5131 <https://github.com/nim-lang/Nim/issues/5131>`_)
- Fixed "Code generation for generics broken by sighashes"
  (`#5135 <https://github.com/nim-lang/Nim/issues/5135>`_)
- Fixed "Regression: importc functions are not declared in generated C code"
  (`#5136 <https://github.com/nim-lang/Nim/issues/5136>`_)
- Fixed "Calling split("") on string hangs program"
  (`#5119 <https://github.com/nim-lang/Nim/issues/5119>`_)
- Fixed "Building dynamic library: undefined references (Linux)"
  (`#4775 <https://github.com/nim-lang/Nim/issues/4775>`_)
- Fixed "Bad codegen for distinct + importc - sighashes regression"
  (`#5137 <https://github.com/nim-lang/Nim/issues/5137>`_)
- Fixed "C++ codegen regression: memset called on a result variable of `importcpp` type"
  (`#5140 <https://github.com/nim-lang/Nim/issues/5140>`_)
- Fixed "C++ codegen regression: using channels leads to broken C++ code"
  (`#5142 <https://github.com/nim-lang/Nim/issues/5142>`_)
- Fixed "Ambiguous call when overloading var and non-var with generic type"
  (`#4519 <https://github.com/nim-lang/Nim/issues/4519>`_)
- Fixed "[Debian]: build.sh error: unknown processor: aarch64"
  (`#2147 <https://github.com/nim-lang/Nim/issues/2147>`_)
- Fixed "RFC: asyncdispatch.poll behaviour"
  (`#5155 <https://github.com/nim-lang/Nim/issues/5155>`_)
- Fixed "Can't access enum members through alias (possible sighashes regression)"
  (`#5148 <https://github.com/nim-lang/Nim/issues/5148>`_)
- Fixed "Type, declared in generic proc body, leads to incorrect codegen (sighashes regression)"
  (`#5147 <https://github.com/nim-lang/Nim/issues/5147>`_)
- Fixed "Compiler SIGSEGV when mixing method and proc"
  (`#5161 <https://github.com/nim-lang/Nim/issues/5161>`_)
- Fixed "Compile-time SIGSEGV when declaring .importcpp method with return value "
  (`#3848 <https://github.com/nim-lang/Nim/issues/3848>`_)
- Fixed "Variable declaration incorrectly parsed"
  (`#2050 <https://github.com/nim-lang/Nim/issues/2050>`_)
- Fixed "Invalid C code when naming a object member "linux""
  (`#5171 <https://github.com/nim-lang/Nim/issues/5171>`_)
- Fixed "[Windows] MinGW within Nim install is missing libraries"
  (`#2723 <https://github.com/nim-lang/Nim/issues/2723>`_)
- Fixed "async: annoying warning for future.finished"
  (`#4948 <https://github.com/nim-lang/Nim/issues/4948>`_)
- Fixed "new import syntax doesn't work?"
  (`#5185 <https://github.com/nim-lang/Nim/issues/5185>`_)
- Fixed "Fixes #1994"
  (`#4874 <https://github.com/nim-lang/Nim/issues/4874>`_)
- Fixed "Can't tell return value of programs with staticExec"
  (`#1994 <https://github.com/nim-lang/Nim/issues/1994>`_)
- Fixed "startProcess() on Windows with poInteractive: Second call fails ("Alle Pipeinstanzen sind ausgelastet")"
  (`#5179 <https://github.com/nim-lang/Nim/issues/5179>`_)
