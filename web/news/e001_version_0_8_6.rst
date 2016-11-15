2009-12-21 Version 0.8.6 released
=================================

.. container:: metadata

  Posted by Andreas Rumpf on 21/12/2009

The version jump from 0.8.2 to 0.8.6 acknowledges the fact that all development
of the compiler is now done in Nimrod.


Bugfixes
--------
- The pragmas ``hint[X]:off`` and ``warning[X]:off`` now work.
- Method call syntax for iterators works again (``for x in lines.split()``).
- Fixed a typo in ``removeDir`` for POSIX that lead to an infinite recursion.
- The compiler now checks that module filenames are valid identifiers.
- Empty patterns for the ``dynlib`` pragma are now possible.
- ``os.parseCmdLine`` returned wrong results for trailing whitespace.
- Inconsequent tuple usage (using the same tuple with and without named fields)
  does not crash the code generator anymore.
- A better error message is provided when the loading of a proc within a
  dynamic lib fails.


Additions
---------
- Added ``system.contains`` for open arrays.
- The PEG module now supports the *search loop operator* ``@``.
- Grammar/parser: ``SAD|IND`` is allowed before any kind of closing bracket.
  This allows for more flexible source code formating.
- The compiler now uses a *bind* table for symbol lookup within a ``bind``
  context. (See `<manual.html#templates>`_ for details.)
- ``discard """my long comment"""`` is now optimized away.
- New ``--floatChecks: on|off`` switches and pragmas for better debugging
  of floating point operations. (See
  `<manual.html#pre-defined-floating-point-types>`_ for details.)
- The manual has been improved. (Many thanks to Philippe Lhoste!)


Changes affecting backwards compatibility
-----------------------------------------
- The compiler does not skip the linking step anymore even if no file
  has changed.
- ``os.splitFile(".xyz")`` now returns ``("", ".xyz", "")`` instead of
  ``("", "", ".xyz")``. So filenames starting with a dot are handled
  differently.
- ``strutils.split(s: string, seps: set[char])`` never yields the empty string
  anymore. This behaviour is probably more appropriate for whitespace splitting.
- The compiler now stops after the ``--version`` command line switch.
- Removed support for enum inheritance in the parser; enum inheritance has
  never been documented anyway.
- The ``msg`` field of ``system.E_base`` has now the type ``string``, instead
  of ``cstring``. This improves memory safety.
