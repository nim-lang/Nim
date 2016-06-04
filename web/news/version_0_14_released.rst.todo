2016-XX-XX Version 0.14.0 released
==================================

Changes affecting backwards compatibility
-----------------------------------------

- ``--out`` and ``--nimcache`` command line arguments are now relative to
  current directory. Previously they were relative to project directory.
- The json module now stores the name/value pairs in objects internally as a
  hash table of type ``fields*: Table[string, JsonNode]`` instead of a
  sequence. This means that order is no longer preserved. When using the
  ``table.mpairs`` iterator only the returned values can be modified, no
  longer the keys.
- The deprecated Nim shebang notation ``#!`` was removed from the language. Use ``#?`` instead.
- The ``using`` statement now means something completely different. You can use the
  new experimental ``this`` pragma to achieve a similar effect to what the old ``using`` statement tried to achieve.
- Typeless parameters have been removed from the language since it would
  clash with ``using``.
- Procedures in ``mersenne.nim`` (Mersenne Twister implementation) no longer
  accept and produce ``int`` values which have platform-dependent size -
  they use ``uint32`` instead.
- The ``strutils.unindent`` procedure has been rewritten. Its parameters now
  match the parameters of ``strutils.indent``. See issue [#4037](https://github.com/nim-lang/Nim/issues/4037)
  for more details.
- The ``matchers`` module has been deprecated. See issue [#2446](https://github.com/nim-lang/Nim/issues/2446)
  for more details.
- The ``json.[]`` no longer returns ``nil`` when a key is not found. Instead it
  raises a ``KeyError`` exception. You can compile with the ``-d:nimJsonGet``
  flag to get a list of usages of ``[]``, as well as to restore the operator's
  previous behaviour.
- When using ``useMalloc``, an additional header containing the size of the
  allocation will be allocated, to support zeroing memory on realloc as expected
  by the language. With this change, ``alloc`` and ``dealloc`` are no longer
  aliases for ``malloc`` and ``free`` - use ``c_malloc`` and ``c_free`` if
  you need that.
- The ``json.%`` operator is now overloaded for ``object``, ``ref object`` and
  ``openarray[T]``.
- The procs related to ``random`` number generation in ``math.nim`` have
  been moved to its own ``random`` module and been reimplemented in pure
  Nim.
- The path handling changed. The project directory is not added to the
  search path automatically anymore. Add this line to your project's
  config to get back the old behaviour: ``--path:"$projectdir"``.
- The ``round`` function in ``math.nim`` now returns a float and has been
  corrected such that the C implementation always rounds up from .5 rather
  than changing the operation for even and odd numbers.
- The ``round`` function now accepts a ``places`` argument to round to a
  given number of places (e.g. round 4.35 to 4.4 if ``places`` is 1).
- In ``strutils.nim``, ``formatSize`` now returns a number representing the
  size in conventional decimal format (e.g. 2.234GB meaning 2.234 GB rather
  than meaning 2.285 GB as in the previous implementation).  By default it
  also uses IEC prefixes (KiB, MiB) etc and optionally uses colloquial names
  (kB, MB etc) and the (SI-preferred) space.
- The ``==`` operator for ``cstring`` now implements a value comparision
  for the C backend (using ``strcmp``), not reference comparisons anymore.
  Convert the cstrings to pointers if you really want reference equality
  for speed.
- HTTP headers are now stored in a ``HttpHeaders`` object instead of a
  ``StringTableRef``. This object allows multiple values to be associated with
  a single key. A new ``httpcore`` module implements it and it is used by
  both ``asynchttpserver`` and ``httpclient``.


Library Additions
-----------------

- The rlocks module has been added providing reentrant lock synchronization
  primitive.
- A generic "sink operator" written as ``&=`` has been added to the ``system`` and the ``net`` modules.
- Added ``strscans`` module that implements a ``scanf`` for easy input extraction.
- Added a version of ``parseutils.parseUntil`` that can deal with a string ``until`` token. The other
  versions are for ``char`` and ``set[char]``.
- Added ``splitDecimal`` to ``math.nim`` to split a floating point value
  into an integer part and a floating part (in the range -1<x<1).
- Added ``trimZeros`` to ```strutils.nim`` to trim trailing zeros in a
  floating point number.
- Added ``formatEng`` to ``strutils.nim`` to format numbers using engineering
  notation.


Compiler Additions
------------------

- Added a new ``--noCppExceptions`` switch that allows to use default exception
  handling (no ``throw`` or ``try``/``catch`` generated) when compiling to C++
  code.

Language Additions
------------------

- Nim now supports a ``.this`` pragma for more notational convenience.
- Nim now supports a different ``using`` statement for more convenience.
- ``include`` statements are not restricted to top level statements anymore.

..
  - Nim now supports ``partial`` object declarations to mitigate the problems
    that arise when types are mutually dependent and yet should be kept in
    different modules.
