Version 0.14.0 released
=======================

.. container:: metadata

  Posted by Dominik Picheta on 07/06/2016

It's been a while since the last release, but we've been very busy in the
meantime. In
addition to working on Nim we have started a
`BountySource campaign <https://salt.bountysource.com/teams/nim>`_ and
announced the pre-release of a new Nim book titled
`Nim in Action <https://manning.com/books/nim-in-action?a_aid=niminaction&a_bid=78a27e81>`_.
Our BountySource campaign has already been very successful, helping us raise
enough funds to surpass 4 of our monthly goals. The companies and individuals
that made this possible are listed on our brand new
`sponsors page <http://nim-lang.org/sponsors.html>`_.

This release includes over 260 bug fixes. As mentioned in the previous release
announcement, one of the focuses of this release was going to be improvements
to the GC. Indeed, the most prominent fixes are related to the GC not collecting
cycles properly. This was a major problem that was triggered typically when
applications using asynchronous I/O were left running for long periods of time.

There have also been many fixes to the way that the compiler sources are
installed. Some applications such as Nimble depend on these sources and they
are now included in the release tarballs. This should fix many of the problems
that users experienced trying to compile the Nimble package manager.

Finally, you will find multiple changes in the standard library. Some of which
unfortunately affects backwards compatibility. This includes the `random`
procedures being moved to a new `random` module, HTTP headers being stored
in a new `HttpHeaders` object and the `round` procedure in the `math` module
being changed to return a `float` instead of an `int`. You can find a full
list of such changes below.

Together with the new release of Nim, we are also releasing a new version of
Nimble. The release notes for it are available on
`GitHub <https://github.com/nim-lang/nimble/blob/master/changelog.markdown#074---06062016>`_.

As always you can download the latest version of Nim from the
`download <http://nim-lang.org/download.html>`_ page.

We hope that you will like this new release. Let us know if you run into
any trouble, have any questions or want to give some feedback. You can get
in touch with us on the `Forum <http://forum.nim-lang.org/>`_,
`IRC <http://webchat.freenode.net/?channels=nim>`_,
`Twitter <http://twitter.com/nim_lang>`_,
or via email contact@nim-lang.org.

Happy coding!

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
  config to get back the old behaviour: ``--path:"$projectdir"``. (Do
  not replace ``$projectdir`` by the project's directory!
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
- The ``==`` operator for ``cstring`` now implements a value comparison
  for the C backend (using ``strcmp``), not reference comparisons anymore.
  Convert the cstrings to pointers if you really want reference equality
  for speed.
- HTTP headers are now stored in a ``HttpHeaders`` object instead of a
  ``StringTableRef``. This object allows multiple values to be associated with
  a single key. A new ``httpcore`` module implements it and it is used by
  both ``asynchttpserver`` and ``httpclient``.


Generic type classes
~~~~~~~~~~~~~~~~~~~~

Generic type classes are now handled properly in the compiler, but this
means code like the following does not compile any longer:

.. code-block:: nim
  type
    Vec3[T] = distinct array[3, T]

  proc vec3*[T](a, b, c: T): Vec3[T] = Vec3([a, b, c])

While every ``Vec3[T]`` is part of the ``Vec3`` type class, the reverse
is not true, not every ``Vec3`` is a ``Vec3[T]``. Otherwise there would
be a subtype relation between ``Vec3[int]`` and ``Vec3[float]`` and there
is none for Nim. The fix is to write this instead:

.. code-block:: nim
  type
    Vec3[T] = distinct array[3, T]

  proc vec3*[T](a, b, c: T): Vec3[T] = Vec3[T]([a, b, c])

Note that in general we don't advise to use ``distinct array``,
use ``object`` instead.


Library Additions
-----------------

- The rlocks module has been added providing a reentrant lock synchronization
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
  See `manual.html#overloading-resolution-automatic-self-insertions`_ for more information.
- Nim now supports a different ``using`` statement for more convenience.
  Consult `manual.html#statements-and-expressions-using-statement`_ for more information.
- ``include`` statements are not restricted to top level statements anymore.

..
  - Nim now supports ``partial`` object declarations to mitigate the problems
    that arise when types are mutually dependent and yet should be kept in
    different modules.

Bugfixes
--------

The list below has been generated based on the commits in Nim's git
repository. As such it lists only the issues which have been closed
via a commit, for a full list see
`this link on Github <https://github.com/nim-lang/Nim/issues?utf8=%E2%9C%93&q=is%3Aissue+closed%3A%222016-01-19+..+2016-06-06%22+>`_.


  - Fixed "Calling generic templates with explicit generic arguments crashes compiler"
    (`#3496 <https://github.com/nim-lang/Nim/issues/3496>`_)
  - Fixed "JS backend - strange utf-8 handling"
    (`#3714 <https://github.com/nim-lang/Nim/issues/3714>`_)
  - Fixed "execvpe is glibc specific"
    (`#3759 <https://github.com/nim-lang/Nim/issues/3759>`_)
  - Fixed "GC stack overflow with in data structures with circular references."
    (`#1895 <https://github.com/nim-lang/Nim/issues/1895>`_)
  - Fixed "Internal compiler error in genTraverseProc"
    (`#3794 <https://github.com/nim-lang/Nim/issues/3794>`_)
  - Fixed "unsafeAddr fails in generic context"
    (`#3736 <https://github.com/nim-lang/Nim/issues/3736>`_)
  - Fixed "Generic converters produce internal errors"
    (`#3799 <https://github.com/nim-lang/Nim/issues/3799>`_)
  - Fixed "Cannot have two anonymous iterators in one proc"
    (`#3788 <https://github.com/nim-lang/Nim/issues/3788>`_)
  - Fixed "pure/net.nim fails to compile with --taintMode:on on HEAD"
    (`#3789 <https://github.com/nim-lang/Nim/issues/3789>`_)
  - Fixed "Using break inside iterator may produce memory/resource leak"
    (`#3802 <https://github.com/nim-lang/Nim/issues/3802>`_)

  - Fixed "--out and --nimcache wrong paths"
    (`#3871 <https://github.com/nim-lang/Nim/issues/3871>`_)
  - Fixed "Release 0.13.0: documentation build failure"
    (`#3823 <https://github.com/nim-lang/Nim/issues/3823>`_)
  - Fixed "https post request"
    (`#3895 <https://github.com/nim-lang/Nim/issues/3895>`_)
  - Fixed "writeFile regression in nimscript"
    (`#3901 <https://github.com/nim-lang/Nim/issues/3901>`_)
  - Fixed "Cannot convert variables to int16 at compile time"
    (`#3916 <https://github.com/nim-lang/Nim/issues/3916>`_)
  - Fixed "Error in concepts when using functions on typedesc"
    (`#3686 <https://github.com/nim-lang/Nim/issues/3686>`_)
  - Fixed "Multiple generic table types with different type signatures lead to compilation errors."
    (`#3669 <https://github.com/nim-lang/Nim/issues/3669>`_)
  - Fixed "Explicit arguments with overloaded procedure?"
    (`#3836 <https://github.com/nim-lang/Nim/issues/3836>`_)
  - Fixed "doc2 generates strange output for proc generated by template"
    (`#3868 <https://github.com/nim-lang/Nim/issues/3868>`_)
  - Fixed "Passing const value as static[] argument to immediate macro leads to infinite memory consumption by compiler"
    (`#3872 <https://github.com/nim-lang/Nim/issues/3872>`_)
  - Fixed "`..<` is not happy with `BiggestInt` from `intVal`"
    (`#3767 <https://github.com/nim-lang/Nim/issues/3767>`_)
  - Fixed "stdtmpl filter does not support anything apart from '#' metachar"
    (`#3924 <https://github.com/nim-lang/Nim/issues/3924>`_)
  - Fixed "lib/pure/net: Can't bind to ports >= 32768"
    (`#3484 <https://github.com/nim-lang/Nim/issues/3484>`_)
  - Fixed "int and float assignment compatibility badly broken for generics"
    (`#3998 <https://github.com/nim-lang/Nim/issues/3998>`_)
  - Fixed "Adding echo statement causes "type mismatch" error"
    (`#3975 <https://github.com/nim-lang/Nim/issues/3975>`_)
  - Fixed "Dynlib error messages should be written to stderr, not stdout"
    (`#3987 <https://github.com/nim-lang/Nim/issues/3987>`_)
  - Fixed "Tests regressions while using the devel branch"
    (`#4005 <https://github.com/nim-lang/Nim/issues/4005>`_)

  - Fixed "Lambda lifting bug: wrong c code generation"
    (`#3995 <https://github.com/nim-lang/Nim/issues/3995>`_)
  - Fixed "VM crashes in asgnComplex"
    (`#3973 <https://github.com/nim-lang/Nim/issues/3973>`_)
  - Fixed "Unknown opcode opcNGetType"
    (`#1152 <https://github.com/nim-lang/Nim/issues/1152>`_)
  - Fixed "`&` operator mutates first operand when used in compileTime proc while assigning result to seq"
    (`#3804 <https://github.com/nim-lang/Nim/issues/3804>`_)
  - Fixed "''nil' statement is deprecated' in macro"
    (`#3561 <https://github.com/nim-lang/Nim/issues/3561>`_)
  - Fixed "vm crash when accessing seq with mitems iterator"
    (`#3731 <https://github.com/nim-lang/Nim/issues/3731>`_)
  - Fixed "`mitems` or `mpairs` does not work for `seq[NimNode]` or `array[T,NimNode]` in a macro"
    (`#3859 <https://github.com/nim-lang/Nim/issues/3859>`_)
  - Fixed "passing "proc `,`()" to nim check causes an infinite loop"
    (`#4036 <https://github.com/nim-lang/Nim/issues/4036>`_)
  - Fixed "--dynlibOverride does not work with {.push dynlib: name.}"
    (`#3646 <https://github.com/nim-lang/Nim/issues/3646>`_)
  - Fixed "system.readChars fails on big len"
    (`#3752 <https://github.com/nim-lang/Nim/issues/3752>`_)
  - Fixed "strutils.unindent"
    (`#4037 <https://github.com/nim-lang/Nim/issues/4037>`_)
  - Fixed "Compiler's infinite recursion in generic resolution"
    (`#2006 <https://github.com/nim-lang/Nim/issues/2006>`_)
  - Fixed "Linux: readLineFromStdin calls quit(0) upon EOF"
    (`#3159 <https://github.com/nim-lang/Nim/issues/3159>`_)
  - Fixed "Forum sign up not possible"
    (`#2446 <https://github.com/nim-lang/Nim/issues/2446>`_)
  - Fixed "Json module - SIGSEGV if key not exists"
    (`#3107 <https://github.com/nim-lang/Nim/issues/3107>`_)
  - Fixed "About asyncdispatch.await and exception"
    (`#3964 <https://github.com/nim-lang/Nim/issues/3964>`_)
  - Fixed "Need testcase for JS backend to ensure closure callbacks don't break"
    (`#3132 <https://github.com/nim-lang/Nim/issues/3132>`_)
  - Fixed "Unexpected behaviour of C++ templates in conjunction with N_NIMCALL"
    (`#4093 <https://github.com/nim-lang/Nim/issues/4093>`_)
  - Fixed "SIGSEGV at compile time when using a compileTime variable as counter"
    (`#4097 <https://github.com/nim-lang/Nim/issues/4097>`_)
  - Fixed "Compiler crash issue on 32-bit machines only"
    (`#4089 <https://github.com/nim-lang/Nim/issues/4089>`_)
  - Fixed "type mismatch: got (<type>) but expected 'outType' in mapIt"
    (`#4124 <https://github.com/nim-lang/Nim/issues/4124>`_)
  - Fixed "Generic type constraints broken?"
    (`#4084 <https://github.com/nim-lang/Nim/issues/4084>`_)
  - Fixed "Invalid C code generated"
    (`#3544 <https://github.com/nim-lang/Nim/issues/3544>`_)
  - Fixed "An exit variable in proc shadows exit function called by quit()"
    (`#3471 <https://github.com/nim-lang/Nim/issues/3471>`_)
  - Fixed "ubuntu 16.04 build error"
    (`#4144 <https://github.com/nim-lang/Nim/issues/4144>`_)
  - Fixed "Ambiguous identifier error should list all possible qualifiers"
    (`#177 <https://github.com/nim-lang/Nim/issues/177>`_)
  - Fixed "Parameters are not captured inside closures inside closure iterators"
    (`#4070 <https://github.com/nim-lang/Nim/issues/4070>`_)
  - Fixed "`$` For array crashes the compiler when assigned to const"
    (`#4040 <https://github.com/nim-lang/Nim/issues/4040>`_)

  - Fixed "Default value for .importcpp enum is initialized incorrectly"
    (`#4034 <https://github.com/nim-lang/Nim/issues/4034>`_)
  - Fixed "Nim doesn't instantiate template parameter in cgen when using procedure return value in for-in loop"
    (`#4110 <https://github.com/nim-lang/Nim/issues/4110>`_)
  - Fixed "Compile-time SIGSEGV when invoking procedures that cannot be evaluated at compile time from a macro"
    (`#3956 <https://github.com/nim-lang/Nim/issues/3956>`_)
  - Fixed "Backtricks inside .emit pragma output incorrect name for types"
    (`#3992 <https://github.com/nim-lang/Nim/issues/3992>`_)
  - Fixed "typedef is generated for .importcpp enums"
    (`#4145 <https://github.com/nim-lang/Nim/issues/4145>`_)
  - Fixed "Incorrect C code generated for nnkEmpty node"
    (`#950 <https://github.com/nim-lang/Nim/issues/950>`_)
  - Fixed "Syntax error in config file appears as general exception without useful info"
    (`#3763 <https://github.com/nim-lang/Nim/issues/3763>`_)
  - Fixed "Converting .importcpp enum to string doesn't work when done inside procs"
    (`#4147 <https://github.com/nim-lang/Nim/issues/4147>`_)
  - Fixed "Enum template specifiers do not work for .importcpp enums when they are used as a parameter"
    (`#4146 <https://github.com/nim-lang/Nim/issues/4146>`_)
  - Fixed "Providing template specifier recursively for .importcpp type doesn't work"
    (`#4148 <https://github.com/nim-lang/Nim/issues/4148>`_)
  - Fixed "sizeof doesn't work for generics in vm"
    (`#4153 <https://github.com/nim-lang/Nim/issues/4153>`_)
  - Fixed "Creating list-like structures in a loop leaks memory indefinitely"
    (`#3793 <https://github.com/nim-lang/Nim/issues/3793>`_)
  - Fixed "Creating list-like structures in a loop leaks memory indefinitely"
    (`#3793 <https://github.com/nim-lang/Nim/issues/3793>`_)
  - Fixed "Enum items generated by a macro have wrong type."
    (`#4066 <https://github.com/nim-lang/Nim/issues/4066>`_)
  - Fixed "Memory leak with default GC"
    (`#3184 <https://github.com/nim-lang/Nim/issues/3184>`_)
  - Fixed "Rationals Overflow Error on 32-bit machine"
    (`#4194 <https://github.com/nim-lang/Nim/issues/4194>`_)

  - Fixed "osproc waitForExit() is ignoring the timeout parameter"
    (`#4200 <https://github.com/nim-lang/Nim/issues/4200>`_)
  - Fixed "Regression: exception parseFloat("-0.0") "
    (`#4212 <https://github.com/nim-lang/Nim/issues/4212>`_)
  - Fixed "JS Codegen: Bad constant initialization order"
    (`#4222 <https://github.com/nim-lang/Nim/issues/4222>`_)
  - Fixed "Term-rewriting macros gives Error: wrong number of arguments"
    (`#4227 <https://github.com/nim-lang/Nim/issues/4227>`_)
  - Fixed "importcpp allowed in body of proc after push"
    (`#4225 <https://github.com/nim-lang/Nim/issues/4225>`_)
  - Fixed "pragma SIGSEGV"
    (`#4001 <https://github.com/nim-lang/Nim/issues/4001>`_)
  - Fixed "Restrict hints to the current project"
    (`#2159 <https://github.com/nim-lang/Nim/issues/2159>`_)
  - Fixed "`unlikely`/`likely` should be no-ops for the Javascript backend"
    (`#3882 <https://github.com/nim-lang/Nim/issues/3882>`_)
  - Fixed ".this pragma doesn't work for fields and procs defined for parent type"
    (`#4177 <https://github.com/nim-lang/Nim/issues/4177>`_)
  - Fixed "VM SIGSEV with compile-time Table"
    (`#3729 <https://github.com/nim-lang/Nim/issues/3729>`_)
  - Fixed "Error during compilation with cpp option on FreeBSD "
    (`#3059 <https://github.com/nim-lang/Nim/issues/3059>`_)
  - Fixed "Compiler doesn't keep type bounds"
    (`#1713 <https://github.com/nim-lang/Nim/issues/1713>`_)
  - Fixed "Stdlib: future: Shortcut proc definition doesn't support, varargs, seqs, arrays, or openarrays"
    (`#4238 <https://github.com/nim-lang/Nim/issues/4238>`_)
  - Fixed "Why don't ``asynchttpserver`` support request-body when ``put`` ``delete``?"
    (`#4221 <https://github.com/nim-lang/Nim/issues/4221>`_)
  - Fixed "Paths for includes in Nim documentation"
    (`#2640 <https://github.com/nim-lang/Nim/issues/2640>`_)
  - Fixed "Compile pragma doesn't work with relative import"
    (`#1262 <https://github.com/nim-lang/Nim/issues/1262>`_)
  - Fixed "Slurp doesn't work with relative imports"
    (`#765 <https://github.com/nim-lang/Nim/issues/765>`_)
  - Fixed "Make tilde expansion consistent"
    (`#786 <https://github.com/nim-lang/Nim/issues/786>`_)
  - Fixed "koch expects nim to be in path for tests?"
    (`#3290 <https://github.com/nim-lang/Nim/issues/3290>`_)
  - Fixed "Don't use relative imports for non relative modules (aka babel libs)"
    (`#546 <https://github.com/nim-lang/Nim/issues/546>`_)
  - Fixed ""echo" on general structs does not work"
    (`#4236 <https://github.com/nim-lang/Nim/issues/4236>`_)
  - Fixed "Changing math.round() and adding math.integer()"
    (`#3473 <https://github.com/nim-lang/Nim/issues/3473>`_)
  - Fixed "Mathematics module missing modf"
    (`#4195 <https://github.com/nim-lang/Nim/issues/4195>`_)
  - Fixed "Passing method to macro causes seg fault"
    (`#1611 <https://github.com/nim-lang/Nim/issues/1611>`_)
  - Fixed "Internal error with "discard quit""
    (`#3532 <https://github.com/nim-lang/Nim/issues/3532>`_)
  - Fixed "SIGSEGV when using object variant in compile time"
    (`#4207 <https://github.com/nim-lang/Nim/issues/4207>`_)
  - Fixed "formatSize has incorrect prefix"
    (`#4198 <https://github.com/nim-lang/Nim/issues/4198>`_)
  - Fixed "Add compiler parameter to generate output from source code filters"
    (`#375 <https://github.com/nim-lang/Nim/issues/375>`_)
  - Fixed "Add engineering notation to string formatting functions"
    (`#4197 <https://github.com/nim-lang/Nim/issues/4197>`_)
  - Fixed "Very minor error in json documentation"
    (`#4255 <https://github.com/nim-lang/Nim/issues/4255>`_)
  - Fixed "can't compile when checking if closure == nil"
    (`#4186 <https://github.com/nim-lang/Nim/issues/4186>`_)
  - Fixed "Strange code gen for procs returning arrays"
    (`#2259 <https://github.com/nim-lang/Nim/issues/2259>`_)
  - Fixed "asynchttpserver may consume unbounded memory reading headers"
    (`#3847 <https://github.com/nim-lang/Nim/issues/3847>`_)

  - Fixed "download page still implies master is default branch"
    (`#4022 <https://github.com/nim-lang/Nim/issues/4022>`_)
  - Fixed "Use standard compiler flags in build script"
    (`#2128 <https://github.com/nim-lang/Nim/issues/2128>`_)
  - Fixed "CentOS 6 (gcc-4.4.7) compilation failed (redefinition of typedef)"
    (`#4272 <https://github.com/nim-lang/Nim/issues/4272>`_)
  - Fixed "doc2 has issues with httpclient"
    (`#4278 <https://github.com/nim-lang/Nim/issues/4278>`_)
  - Fixed "tuples/tuple_with_nil fails without unsigned module"
    (`#3579 <https://github.com/nim-lang/Nim/issues/3579>`_)
