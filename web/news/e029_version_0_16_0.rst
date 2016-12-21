Version 0.16.0 released
=======================

.. container:: metadata

  Posted by xyz on dd/mm/yyyy

We're happy to announce that the latest release of Nim, version 0.16.0, is now
available!

As always, you can grab the latest version from the
`downloads page <http://nim-lang.org/download.html>`_.

This release includes almost xyz bug fixes and improvements. To see a full list
of changes, take a look at the detailed changelog
`below <#changelog>`_.

Some of the most significant changes in this release include: xyz


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


Tool Additions
--------------


Compiler Additions
------------------


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
`this link on Github <https://github.com/nim-lang/Nim/issues?utf8=%E2%9C%93&q=is%3Aissue+closed%3A%222016-06-22+..+2016-09-30%22+>`_.
