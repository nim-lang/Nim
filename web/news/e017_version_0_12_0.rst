2015-10-27 Version 0.12.0 released
==================================

.. container:: metadata

  Posted by Dominik Picheta on 27/10/2015

The Nim community of developers is proud to announce the new version of the
Nim compiler. This has been a long time coming as the last release has been
made over 5 months ago!

This release includes some changes which affect backwards compatibility,
one major change is that now the hash table ``[]`` operators now raise a
``KeyError`` exception when the key does not exist.

Some of the more exciting new features include: the ability to unpack tuples
in any assignment context, the introduction of `NimScript <docs/nims.html>`_,
and improvements to the type inference of lambdas.

There are of course many many many bug fixes included with this release.
We are getting closer and closer to a 1.0 release and are hoping that only
a few 0.x releases will be necessary before we are happy to release version 1.0.

As always you can download the latest version of Nim from the
`download <download.html>`_ page.

For a more detailed list of changes look below. Some of the upcoming breaking
changes are also documented in this forum
`thread <http://forum.nim-lang.org/t/1708>`_.

Changes affecting backwards compatibility
-----------------------------------------
- The regular expression modules, ``re`` and ``nre`` now depend on version
  8.36 of PCRE. If you have an older version you may see a message similar
  to ``could not import: pcre_free_study`` output when you start your
  program. See `this issue <https://github.com/docopt/docopt.nim/issues/13>`_
  for more information.
- ``tables.[]``, ``strtabs.[]``, ``critbits.[]`` **now raise**
  the ``KeyError`` **exception when the key does not exist**! Use the
  new ``getOrDefault`` instead to get the old behaviour. Compile all your
  code with ``-d:nimTableGet`` to get a listing of where your code
  uses ``[]``!
- The ``rawsockets`` module has been renamed to ``nativesockets`` to avoid
  confusion with TCP/IP raw sockets, so ``newNativeSocket`` should be used
  instead of ``newRawSocket``.
- The ``miliseconds`` property of ``times.TimeInterval`` is now ``milliseconds``.
  Code accessing that property is deprecated and code using ``miliseconds``
  during object initialization or as a named parameter of ``initInterval()``
  will need to be updated.
- ``std.logging`` functions no longer do formatting and semantically treat
  their arguments just like ``echo`` does. Affected functions: ``log``,
  ``debug``, ``info``, ``warn``, ``error``, ``fatal``. Custom subtypes of
  ``Logger`` also need to be adjusted accordingly.
- Floating point numbers can now look like ``2d`` (float64)
  and ``2f`` (float32) which means imports like ``import scene/2d/sprite``
  do not work anymore. Instead quotes have to be
  used: ``import "scene/2d/sprite"``. The former code never was valid Nim.
- The Windows API wrapper (``windows.nim``) is now not part of the official
  distribution anymore. Instead use the ``oldwinapi`` Nimble package.
- There is now a clear distinction between ``--os:standalone``
  and ``--gc:none``. So if you use ``--os:standalone`` ensure you also use
  ``--gc:none``. ``--os:standalone`` without ``--gc:none`` is now a version
  that doesn't depend on any OS but includes the GC. However this version
  is currently untested!
- All procedures which construct a ``Socket``/``AsyncSocket`` now need to
  specify the socket domain, type and protocol. The param name
  ``typ: SockType`` (in ``newSocket``/``newAsyncSocket`` procs) was also
  renamed to ``sockType``. The param ``af`` in the ``connect`` procs was
  removed. This affects ``asyncnet``, ``asyncdispatch``, ``net``, and
  ``rawsockets``.
- ``varargs[typed]`` and ``varargs[untyped]`` have been refined and now work
  as expected. However ``varargs[untyped]`` is not an alias anymore for
  ``varargs[expr]``. So if your code breaks for ``varargs[untyped]``, use
  ``varargs[expr]`` instead. The same applies to ``varargs[typed]`` vs
  ``varargs[stmt]``.
- ``sequtils.delete`` doesn't take confusing default arguments anymore.
- ``system.free`` was an error-prone alias to ``system.dealloc`` and has
  been removed.
- ``macros.high`` never worked and the manual says ``high`` cannot be
  overloaded, so we removed it with no deprecation cycle.
- To use the ``parallel`` statement you now have to
  use the ``--experimental`` mode.
- Toplevel procs of calling convention ``closure`` never worked reliably
  and are now deprecated and will be removed from the language. Instead you
  have to insert type conversions
  like ``(proc (a, b: int) {.closure.})(myToplevelProc)`` if necessary.
- The modules ``libffi``, ``sdl``, ``windows``, ``zipfiles``, ``libzip``,
  ``zlib``, ``zzip``, ``dialogs``, ``expat``, ``graphics``, ``libcurl``,
  ``sphinx`` have been moved out of the stdlib and are Nimble packages now.
- The constant fights between 32 and 64 bit DLLs on Windows have been put to
  an end: The standard distribution now ships with 32 and 64 bit versions
  of all the DLLs the standard library needs. This means that the following
  DLLs are now split into 32 and 64 versions:

  * ``pcre.dll``: Split into ``pcre32.dll`` and ``pcre64.dll``.
  * ``pdcurses.dll``: Split into ``pdcurses32.dll`` and ``pdcurses64.dll``.
  * ``sqlite3.dll``: Split into ``sqlite3_32.dll`` and ``sqlite3_64.dll``.
  * ``ssleay32.dll``: Split into ``ssleay32.dll`` and ``ssleay64.dll``.
  * ``libeay32.dll``: Split into ``libeay32.dll`` and ``libeay64.dll``.

  Compile with ``-d:nimOldDLLs`` to make the stdlib use the old DLL names.
- Nim VM now treats objects as ``nkObjConstr`` nodes, and not ``nkPar`` nodes
  as it was previously. Macros that generate ``nkPar`` nodes when object is
  expected are likely to break. Macros that expect ``nkPar`` nodes to which
  objects are passed are likely to break as well.
- Base methods now need to be annotated with the ``base`` pragma. This makes
  multi methods less error-prone to use with the effect system.
- Nim's parser directive ``#!`` is now ``#?`` in order to produce no conflicts
  with Unix's ``#!``.
- An implicit return type for an iterator is now deprecated. Use ``auto`` if
  you want more type inference.
- The type ``auto`` is now a "multi-bind" metatype, so the following compiles:

  .. code-block:: nim
    proc f(x, y: auto): auto =
      result = $x & y

    echo f(0, "abc")
- The ``ftpclient`` module is now deprecated in favour of the
  ``asyncftpclient`` module.
- In sequtils.nim renamed ``repeat`` function to ``cycle`` (concatenating
  a sequence by itself the given times), and also introduced ``repeat``,
  which repeats an element the given times.
- The function ``map`` is moved to sequtils.nim. The inplace ``map`` version
  is renamed to ``apply``.
- The template ``mapIt`` now doesn't require the result's type parameter.
  Also the inplace ``mapIt`` is renamed to ``apply``.
- The compiler is now stricter with what is allowed as a case object
  discriminator. The following code used to compile but was not supported
  completely and so now fails:

.. code-block:: nim
    type
        DataType* {.pure.} = enum
            Char = 1,
            Int8 = 2,
            Int16 = 3,
            Int32 = 4,
            Int64 = 5,
            Float32 = 6,
            Float64 = 7

        DataSeq* = object
            case kind* : DataType
            of DataType.Char: charSeq* : seq[char]
            of DataType.Int8: int8Seq* : seq[int8]
            of DataType.Int16: int16Seq* : seq[int16]
            of DataType.Int32: int32Seq* : seq[int32]
            of DataType.Int64: int64Seq* : seq[int64]
            of DataType.Float32: float32Seq* : seq[float32]
            of DataType.Float64: float64Seq* : seq[float64]

            length* : int



Library Additions
-----------------

- The nre module has been added, providing a better interface to PCRE than re.
- The ``expandSymlink`` proc has been added to the ``os`` module.
- The ``tailDir`` proc has been added to the ``os`` module.
- Define ``nimPinToCpu`` to make the ``threadpool`` use explicit thread
  affinities. This can speed up or slow down the thread pool; it's up to you
  to benchmark it.
- ``strutils.formatFloat`` and ``formatBiggestFloat`` do not depend on the C
  locale anymore and now take an optional ``decimalSep = '.'`` parameter.
- Added ``unicode.lastRune``, ``unicode.graphemeLen``.


Compiler Additions
------------------

- The compiler now supports a new configuration system based on
  `NimScript <docs/nims.html>`_.
- The compiler finally considers symbol binding rules in templates and
  generics for overloaded ``[]``, ``[]=``, ``{}``, ``{}=`` operators
  (issue `#2599 <https://github.com/nim-lang/Nim/issues/2599>`_).
- The compiler now supports a `bitsize pragma <docs/manual.html#pragmas-bitsize-pragma>`_
  for constructing bitfields.
- Added a new ``--reportConceptFailures`` switch for better debugging of
  concept related type mismatches. This can also be used to debug
  ``system.compiles`` failures.


Language Additions
------------------

- ``system.unsafeAddr`` can be used to access the address of a ``let``
  variable or parameter for C interoperability. Since technically this
  makes parameters and ``let`` variables mutable, it is considered even more
  unsafe than the ordinary ``addr`` builtin.
- Added ``macros.getImpl`` that can be used to access the implementation of
  a routine or a constant. This allows for example for user-defined inlining
  of function calls.
- Tuple unpacking finally works in a non-var/let context: ``(x, y) = f()``
  is allowed. Note that this doesn't declare ``x`` and ``y`` variables, for
  this ``let (x, y) = f()`` still needs to be used.
- ``when nimvm`` can now be used for compiletime versions of some code
  sections. Click `here <docs/manual.html#when-nimvm-statement>`_ for details.
- Usage of the type ``NimNode`` in a proc now implicitly annotates the proc
  with ``.compileTime``. This means generics work much better for ``NimNode``.


Bugfixes
--------
- Fixed "Compiler internal error on iterator it(T: typedesc[Base]) called with it(Child), where Child = object of Base"
  (`#2662 <https://github.com/Araq/Nim/issues/2662>`_)
- Fixed "repr() misses base object field in 2nd level derived object"
  (`#2749 <https://github.com/Araq/Nim/issues/2749>`_)
- Fixed "nimsuggest doesn't work more than once on the non-main file"
  (`#2694 <https://github.com/Araq/Nim/issues/2694>`_)
- Fixed "JS Codegen. Passing arguments by var in certain cases leads to invalid JS."
  (`#2798 <https://github.com/Araq/Nim/issues/2798>`_)
- Fixed ""check" proc in unittest.nim prevents the propagation of changes to var parameters."
  (`#964 <https://github.com/Araq/Nim/issues/964>`_)
- Fixed "Excessive letters in integer literals are not an error"
  (`#2523 <https://github.com/Araq/Nim/issues/2523>`_)
- Fixed "Unicode dashes as "lisp'ish" alternative to hump and snake notation"
  (`#2811 <https://github.com/Araq/Nim/issues/2811>`_)
- Fixed "Bad error message when trying to construct an object incorrectly"
  (`#2584 <https://github.com/Araq/Nim/issues/2584>`_)
- Fixed "Determination of GC safety of globals is broken "
  (`#2854 <https://github.com/Araq/Nim/issues/2854>`_)
- Fixed "v2 gc crashes compiler"
  (`#2687 <https://github.com/Araq/Nim/issues/2687>`_)
- Fixed "Compile error using object in const array"
  (`#2774 <https://github.com/Araq/Nim/issues/2774>`_)
- Fixed "httpclient async requests with method httpPOST isn't sending Content-Length header"
  (`#2884 <https://github.com/Araq/Nim/issues/2884>`_)
- Fixed "Streams module not working with JS backend"
  (`#2148 <https://github.com/Araq/Nim/issues/2148>`_)
- Fixed "Sign of certain short constants is wrong"
  (`#1179 <https://github.com/Araq/Nim/issues/1179>`_)
- Fixed "Symlinks to directories reported as symlinks to files"
  (`#1985 <https://github.com/Araq/Nim/issues/1985>`_)
- Fixed "64-bit literals broken on x86"
  (`#2909 <https://github.com/Araq/Nim/issues/2909>`_)
- Fixed "import broken for certain names"
  (`#2904 <https://github.com/Araq/Nim/issues/2904>`_)
- Fixed "Invalid UTF-8 strings in JavaScript"
  (`#2917 <https://github.com/Araq/Nim/issues/2917>`_)
- Fixed "[JS][Codegen] Initialising object doesn't create unmentioned fields."

  (`#2617 <https://github.com/Araq/Nim/issues/2617>`_)
- Fixed "Table returned from proc computed at compile time is missing keys:"
  (`#2297 <https://github.com/Araq/Nim/issues/2297>`_)
- Fixed "Clarify copyright status for some files"
  (`#2949 <https://github.com/Araq/Nim/issues/2949>`_)
- Fixed "math.nim: trigonometry: radians to degrees conversion"
  (`#2881 <https://github.com/Araq/Nim/issues/2881>`_)
- Fixed "xoring unsigned integers yields RangeError in certain conditions"
  (`#2979 <https://github.com/Araq/Nim/issues/2979>`_)
- Fixed "Directly checking equality between procs"
  (`#2985 <https://github.com/Araq/Nim/issues/2985>`_)
- Fixed "Compiler crashed, but there have to be meaningful error message"
  (`#2974 <https://github.com/Araq/Nim/issues/2974>`_)
- Fixed "repr is broken"
  (`#2992 <https://github.com/Araq/Nim/issues/2992>`_)
- Fixed "Ipv6 devel - add IPv6 support for asyncsockets, make AF_INET6 a default"
  (`#2976 <https://github.com/Araq/Nim/issues/2976>`_)
- Fixed "Compilation broken on windows"
  (`#2996 <https://github.com/Araq/Nim/issues/2996>`_)
- Fixed "'u64 literal conversion compiler error"
  (`#2731 <https://github.com/Araq/Nim/issues/2731>`_)
- Fixed "Importing 'impure' libraries while using threads causes segfaults"
  (`#2672 <https://github.com/Araq/Nim/issues/2672>`_)
- Fixed "Uncatched exception in async procedure on raise statement"
  (`#3014 <https://github.com/Araq/Nim/issues/3014>`_)
- Fixed "nim doc2 fails in Mac OS X due to system.nim (possibly related to #1898)"
  (`#3005 <https://github.com/Araq/Nim/issues/3005>`_)
- Fixed "IndexError when rebuilding Nim on iteration 2"
  (`#3018 <https://github.com/Araq/Nim/issues/3018>`_)
- Fixed "Assigning large const set to variable looses some information"
  (`#2880 <https://github.com/Araq/Nim/issues/2880>`_)
- Fixed "Inconsistent generics behavior"
  (`#3022 <https://github.com/Araq/Nim/issues/3022>`_)
- Fixed "Compiler breaks on float64 division"
  (`#3028 <https://github.com/Araq/Nim/issues/3028>`_)
- Fixed "Confusing error message comparing string to nil "
  (`#2935 <https://github.com/Araq/Nim/issues/2935>`_)
- Fixed "convert 64bit number to float on 32bit"
  (`#1463 <https://github.com/Araq/Nim/issues/1463>`_)
- Fixed "Type redefinition and construction will break nim check"
  (`#3032 <https://github.com/Araq/Nim/issues/3032>`_)
- Fixed "XmlParser fails on very large XML files without new lines"
  (`#2429 <https://github.com/Araq/Nim/issues/2429>`_)
- Fixed "Error parsing arguments with whitespaces"
  (`#2874 <https://github.com/Araq/Nim/issues/2874>`_)
- Fixed "Crash when missing one arg and used a named arg"
  (`#2993 <https://github.com/Araq/Nim/issues/2993>`_)
- Fixed "Wrong number of arguments in assert will break nim check"
  (`#3044 <https://github.com/Araq/Nim/issues/3044>`_)
- Fixed "Wrong const definition will break nim check"
  (`#3041 <https://github.com/Araq/Nim/issues/3041>`_)
- Fixed "Wrong set declaration will break nim check"
  (`#3040 <https://github.com/Araq/Nim/issues/3040>`_)
- Fixed "Compiler segfault (type section)"
  (`#2540 <https://github.com/Araq/Nim/issues/2540>`_)
- Fixed "Segmentation fault when compiling this code"
  (`#3038 <https://github.com/Araq/Nim/issues/3038>`_)
- Fixed "Kill nim i"
  (`#2633 <https://github.com/Araq/Nim/issues/2633>`_)
- Fixed "Nim check will break on wrong array declaration"
  (`#3048 <https://github.com/Araq/Nim/issues/3048>`_)
- Fixed "boolVal seems to be broken"
  (`#3046 <https://github.com/Araq/Nim/issues/3046>`_)
- Fixed "Nim check crashes on wrong set/array declaration inside ref object"
  (`#3062 <https://github.com/Araq/Nim/issues/3062>`_)
- Fixed "Nim check crashes on incorrect generic arg definition"
  (`#3051 <https://github.com/Araq/Nim/issues/3051>`_)
- Fixed "Nim check crashes on iterating nonexistent var"
  (`#3053 <https://github.com/Araq/Nim/issues/3053>`_)
- Fixed "Nim check crashes on wrong param set declaration + iteration"
  (`#3054 <https://github.com/Araq/Nim/issues/3054>`_)
- Fixed "Wrong sharing of static_t instantations"
  (`#3112 <https://github.com/Araq/Nim/issues/3112>`_)
- Fixed "Automatically generated proc conflicts with user-defined proc when .exportc.'ed"
  (`#3134 <https://github.com/Araq/Nim/issues/3134>`_)
- Fixed "getTypeInfo call crashes nim"
  (`#3099 <https://github.com/Araq/Nim/issues/3099>`_)
- Fixed "Array ptr dereference"
  (`#2963 <https://github.com/Araq/Nim/issues/2963>`_)
- Fixed "Internal error when `repr`-ing a type directly"
  (`#3079 <https://github.com/Araq/Nim/issues/3079>`_)
- Fixed "unknown type name 'TNimType' after importing typeinfo module"
  (`#2841 <https://github.com/Araq/Nim/issues/2841>`_)
- Fixed "Can export a template twice and from inside a block"
  (`#1738 <https://github.com/Araq/Nim/issues/1738>`_)
- Fixed "C Codegen: C Types are defined after their usage in certain cases"
  (`#2823 <https://github.com/Araq/Nim/issues/2823>`_)
- Fixed "s.high refers to the current seq instead of the old one"
  (`#1832 <https://github.com/Araq/Nim/issues/1832>`_)
- Fixed "Error while unmarshaling null values"
  (`#3149 <https://github.com/Araq/Nim/issues/3149>`_)
- Fixed "Inference of `static[T]` in sequences"
  (`#3144 <https://github.com/Araq/Nim/issues/3144>`_)
- Fixed "Argument named "closure" to proc inside template interfere with closure pragma"
  (`#3171 <https://github.com/Araq/Nim/issues/3171>`_)
- Fixed "Internal error with aliasing inside template"
  (`#3158 <https://github.com/Araq/Nim/issues/3158>`_)
- Fixed "Cardinality of sets prints unexpected value"
  (`#3135 <https://github.com/Araq/Nim/issues/3135>`_)
- Fixed "Nim crashes on const assignment from function returning var ref object"
  (`#3103 <https://github.com/Araq/Nim/issues/3103>`_)
- Fixed "`repr` cstring"
  (`#3080 <https://github.com/Araq/Nim/issues/3080>`_)
- Fixed "Nim check crashes on wrong enum declaration"
  (`#3052 <https://github.com/Araq/Nim/issues/3052>`_)
- Fixed "Compiler assertion when evaluating template with static[T]"
  (`#1858 <https://github.com/Araq/Nim/issues/1858>`_)
- Fixed "Erroneous overflow in iterators when compiler built with overflowChecks enabled"
  (`#3140 <https://github.com/Araq/Nim/issues/3140>`_)
- Fixed "Unicode dashes as "lisp'ish" alternative to hump and snake notation"
  (`#2811 <https://github.com/Araq/Nim/issues/2811>`_)
- Fixed "Calling discardable proc from a defer is an error."
  (`#3185 <https://github.com/Araq/Nim/issues/3185>`_)
- Fixed "Defer statement at the end of a block produces ICE"
  (`#3186 <https://github.com/Araq/Nim/issues/3186>`_)
- Fixed "Call to `createU` fails to compile"
  (`#3193 <https://github.com/Araq/Nim/issues/3193>`_)
- Fixed "VM crash when accessing array's element"
  (`#3192 <https://github.com/Araq/Nim/issues/3192>`_)
- Fixed "Unexpected proc invoked when different modules add procs to a type from a 3rd module"
  (`#2664 <https://github.com/Araq/Nim/issues/2664>`_)
- Fixed "Nim crashes on conditional declaration inside a template"
  (`#2670 <https://github.com/Araq/Nim/issues/2670>`_)
- Fixed "Iterator names conflict within different scopes"
  (`#2752 <https://github.com/Araq/Nim/issues/2752>`_)
- Fixed "VM: Cannot assign int value to ref variable"
  (`#1329 <https://github.com/Araq/Nim/issues/1329>`_)
- Fixed "Incorrect code generated for tagged unions with enums not starting at zero"
  (`#3096 <https://github.com/Araq/Nim/issues/3096>`_)
- Fixed "Compile time procs using forward declarations are silently ignored"
  (`#3066 <https://github.com/Araq/Nim/issues/3066>`_)
- Fixed "re binding error in generic"
  (`#1965 <https://github.com/Araq/Nim/issues/1965>`_)
- Fixed "os.getCreationTime is incorrect/impossible on Posix systems"
  (`#1058 <https://github.com/Araq/Nim/issues/1058>`_)
- Fixed "Improve error message for osproc.startProcess when command does not exist"
  (`#2183 <https://github.com/Araq/Nim/issues/2183>`_)
- Fixed "gctest segfaults with --gc:markandsweep on x86_64"
  (`#2305 <https://github.com/Araq/Nim/issues/2305>`_)
- Fixed "Coroutine changes break compilation on unsupported architectures"
  (`#3245 <https://github.com/Araq/Nim/issues/3245>`_)
- Fixed "Bugfix: Windows 32bit  TinyCC support issue fixed"
  (`#3237 <https://github.com/Araq/Nim/issues/3237>`_)
- Fixed "db_mysql getValue() followed by exec() causing error"
  (`#3220 <https://github.com/Araq/Nim/issues/3220>`_)
- Fixed "xmltree.newEntity creates xnCData instead of xnEntity"
  (`#3282 <https://github.com/Araq/Nim/issues/3282>`_)
- Fixed "Methods and modules don't work together"
  (`#2590 <https://github.com/Araq/Nim/issues/2590>`_)
- Fixed "String slicing not working in the vm"
  (`#3300 <https://github.com/Araq/Nim/issues/3300>`_)
- Fixed "internal error: evalOp(mTypeOf)"
  (`#3230 <https://github.com/Araq/Nim/issues/3230>`_)
- Fixed "#! source code prefix collides with Unix Shebang"
  (`#2559 <https://github.com/Araq/Nim/issues/2559>`_)
- Fixed "wrong codegen for constant object"
  (`#3195 <https://github.com/Araq/Nim/issues/3195>`_)
- Fixed "Doc comments inside procs with implicit returns don't work"
  (`#1528 <https://github.com/Araq/Nim/issues/1528>`_)
