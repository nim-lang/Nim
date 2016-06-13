Version 0.15.0 released
=======================

.. container:: metadata

  Posted by Dominik Picheta on 17/09/2016

Some text here.

Changes affecting backwards compatibility
-----------------------------------------

- De-deprecated ``re.nim`` because we have too much code using it
  and it got the basic API right.

Library Additions
-----------------

- Added ``readHeaderRow`` and ``rowEntry`` to ``parsecsv.nim`` to provide
  a lightweight alternative to python's ``csv.DictReader``.
- Added ``setStdIoUnbuffered`` proc to ``system.nim`` to enable unbuffered I/O.

- Added ``center``, ``rsplit``, and ``expandTabs`` to ``strutils.nim`` to
  provide similar Python functionality for Nim's strings.

- Added ``isTitle``, ``title``, and ``swapCase`` to ``unicode.nim`` to
  provide unicode aware string case manipulation.

- Added a new module ``lib/pure/strmisc.nim`` to hold uncommon string
  operations. Currently contains ``partition`` and ``rpartition``.

Compiler Additions
------------------

Language Additions
------------------

Bugfixes
--------
