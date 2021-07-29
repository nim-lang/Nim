====================
Nim Standard Library
====================

:Author: Andreas Rumpf
:Version: |nimversion|

.. default-role:: code
.. include:: rstcommon.rst
.. contents::

Nim's library is divided into *pure libraries*, *impure libraries*, and *wrappers*.

Pure libraries do not depend on any external ``*.dll`` or ``lib*.so`` binary
while impure libraries do. A wrapper is an impure library that is a very
low-level interface to a C library.

Read this `document <apis.html>`_ for a quick overview of the API design.


Nimble
======

Nim's standard library only covers the basics, check
out `<https://nimble.directory/>`_ for a list of 3rd party packages.


Pure libraries
==============

Automatic imports
-----------------

* `system <system.html>`_
  Basic procs and operators that every program needs. It also provides IO
  facilities for reading and writing text and binary files. It is imported
  implicitly by the compiler. Do not import it directly. It relies on compiler
  magic to work.

* `threads <threads.html>`_
  Basic Nim thread support. **Note:** This is part of the system module. Do not
  import it explicitly. Enabled with `--threads:on`:option:.

* `channels_builtin <channels_builtin.html>`_
  Nim message passing support for threads. **Note:** This is part of the
  system module. Do not import it explicitly. Enabled with `--threads:on`:option:.


Core
----

* `atomics <atomics.html>`_
  Types and operations for atomic operations and lockless algorithms.

* `bitops <bitops.html>`_
  Provides a series of low-level methods for bit manipulation.

* `cpuinfo <cpuinfo.html>`_
  This module implements procs to determine the number of CPUs / cores.

* `endians <endians.html>`_
  This module contains helpers that deal with different byte orders.

* `lenientops <lenientops.html>`_
  Provides binary operators for mixed integer/float expressions for convenience.

* `locks <locks.html>`_
  Locks and condition variables for Nim.

* `macrocache <macrocache.html>`_
  Provides an API for macros to collect compile-time information across modules.

* `macros <macros.html>`_
  Contains the AST API and documentation of Nim for writing macros.

* `rlocks <rlocks.html>`_
  Reentrant locks for Nim.

* `typeinfo <typeinfo.html>`_
  Provides (unsafe) access to Nim's run-time type information.

* `typetraits <typetraits.html>`_
  This module defines compile-time reflection procs for working with types.

* `volatile <volatile.html>`_
  This module contains code for generating volatile loads and stores,
  which are useful in embedded and systems programming.


Algorithms
----------

* `algorithm <algorithm.html>`_
  This module implements some common generic algorithms like sort or binary search.

* `enumutils <enumutils.html>`_
  This module adds functionality for the built-in `enum` type.

* `sequtils <sequtils.html>`_
  This module implements operations for the built-in `seq` type
  which were inspired by functional programming languages.

* `setutils <setutils.html>`_
  This module adds functionality for the built-in `set` type.


Collections
-----------

* `critbits <critbits.html>`_
  This module implements a *crit bit tree* which is an efficient
  container for a sorted set of strings, or a sorted mapping of strings.

* `deques <deques.html>`_
  Implementation of a double-ended queue.
  The underlying implementation uses a `seq`.

* `heapqueue <heapqueue.html>`_
  Implementation of a binary heap data structure that can be used as a priority queue.

* `intsets <intsets.html>`_
  Efficient implementation of a set of ints as a sparse bit set.

* `lists <lists.html>`_
  Nim linked list support. Contains singly and doubly linked lists and
  circular lists ("rings").

* `options <options.html>`_
  The option type encapsulates an optional value.

* `packedsets <packedsets.html>`_
  Efficient implementation of a set of ordinals as a sparse bit set.

* `sets <sets.html>`_
  Nim hash set support.

* `sharedlist <sharedlist.html>`_
  Nim shared linked list support. Contains a shared singly-linked list.

* `sharedtables <sharedtables.html>`_
  Nim shared hash table support. Contains shared tables.

* `tables <tables.html>`_
  Nim hash table support. Contains tables, ordered tables, and count tables.


String handling
---------------

* `cstrutils <cstrutils.html>`_
  Utilities for `cstring` handling.

* `editdistance <editdistance.html>`_
  This module contains an algorithm to compute the edit distance between two
  Unicode strings.

* `encodings <encodings.html>`_
  Converts between different character encodings. On UNIX, this uses
  the `iconv` library, on Windows the Windows API.

* `parseutils <parseutils.html>`_
  This module contains helpers for parsing tokens, numbers, identifiers, etc.

* `pegs <pegs.html>`_
  This module contains procedures and operators for handling PEGs.

* `punycode <punycode.html>`_
  Implements a representation of Unicode with the limited ASCII character subset.

* `ropes <ropes.html>`_
  This module contains support for a *rope* data type.
  Ropes can represent very long strings efficiently;
  in particular, concatenation is done in O(1) instead of O(n).

* `strbasics <strbasics.html>`_
  This module provides some high performance string operations.

* `strformat <strformat.html>`_
  Macro based standard string interpolation/formatting. Inspired by
  Python's f-strings.

* `strmisc <strmisc.html>`_
  This module contains uncommon string handling operations that do not
  fit with the commonly used operations in strutils.

* `strscans <strscans.html>`_
  This module contains a `scanf` macro for convenient parsing of mini languages.

* `strtabs <strtabs.html>`_
  The `strtabs` module implements an efficient hash table that is a mapping
  from strings to strings. Supports a case-sensitive, case-insensitive and
  style-insensitive modes.

* `strutils <strutils.html>`_
  This module contains common string handling operations like changing
  case of a string, splitting a string into substrings, searching for
  substrings, replacing substrings.

* `unicode <unicode.html>`_
  This module provides support to handle the Unicode UTF-8 encoding.

* `unidecode <unidecode.html>`_
  It provides a single proc that does Unicode to ASCII transliterations.
  Based on Python's Unidecode module.

* `wordwrap <wordwrap.html>`_
  This module contains an algorithm to wordwrap a Unicode string.


Time handling
-------------

* `monotimes <monotimes.html>`_
  The `monotimes` module implements monotonic timestamps.

* `times <times.html>`_
  The `times` module contains support for working with time.


Generic Operating System Services
---------------------------------

* `distros <distros.html>`_
  This module implements the basics for OS distribution ("distro") detection
  and the OS's native package manager.
  Its primary purpose is to produce output for Nimble packages,
  but it also contains the widely used **Distribution** enum
  that is useful for writing platform-specific code.
  See `packaging <packaging.html>`_ for hints on distributing Nim using OS packages.

* `dynlib <dynlib.html>`_
  This module implements the ability to access symbols from shared libraries.

* `marshal <marshal.html>`_
  Contains procs for serialization and deserialization of arbitrary Nim
  data structures.

* `memfiles <memfiles.html>`_
  This module provides support for memory-mapped files (Posix's `mmap`)
  on the different operating systems.

* `os <os.html>`_
  Basic operating system facilities like retrieving environment variables,
  reading command line arguments, working with directories, running shell
  commands, etc.

* `osproc <osproc.html>`_
  Module for process communication beyond `os.execShellCmd`.

* `streams <streams.html>`_
  This module provides a stream interface and two implementations thereof:
  the `FileStream` and the `StringStream` which implement the stream
  interface for Nim file objects (`File`) and strings. Other modules
  may provide other implementations for this standard stream interface.

* `terminal <terminal.html>`_
  This module contains a few procedures to control the *terminal*
  (also called *console*). The implementation simply uses ANSI escape
  sequences and does not depend on any other module.


Math libraries
--------------

* `complex <complex.html>`_
  This module implements complex numbers and relevant mathematical operations.

* `fenv <fenv.html>`_
  Floating-point environment. Handling of floating-point rounding and
  exceptions (overflow, zero-divide, etc.).

* `math <math.html>`_
  Mathematical operations like cosine, square root.

* `random <random.html>`_
  Fast and tiny random number generator.

* `rationals <rationals.html>`_
  This module implements rational numbers and relevant mathematical operations.

* `stats <stats.html>`_
  Statistical analysis.

* `sums <sums.html>`_
  Accurate summation functions.

* `sysrand <sysrand.html>`_
  Cryptographically secure pseudorandom number generator.


Internet Protocols and Support
------------------------------

* `asyncdispatch <asyncdispatch.html>`_
  This module implements an asynchronous dispatcher for IO operations.

* `asyncfile <asyncfile.html>`_
  This module implements asynchronous file reading and writing using
  `asyncdispatch`.

* `asyncftpclient <asyncftpclient.html>`_
  This module implements an asynchronous FTP client using the `asyncnet`
  module.

* `asynchttpserver <asynchttpserver.html>`_
  This module implements an asynchronous HTTP server using the `asyncnet`
  module.

* `asyncnet <asyncnet.html>`_
  This module implements asynchronous sockets based on the `asyncdispatch`
  module.

* `asyncstreams <asyncstreams.html>`_
  This module provides `FutureStream` - a future that acts as a queue.

* `cgi <cgi.html>`_
  This module implements helpers for CGI applications.

* `cookies <cookies.html>`_
  This module contains helper procs for parsing and generating cookies.

* `httpclient <httpclient.html>`_
  This module implements a simple HTTP client which supports both synchronous
  and asynchronous retrieval of web pages.

* `mimetypes <mimetypes.html>`_
  This module implements a mimetypes database.

* `nativesockets <nativesockets.html>`_
  This module implements a low-level sockets API.

* `net <net.html>`_
  This module implements a high-level sockets API. It replaces the
  `sockets` module.

* `selectors <selectors.html>`_
  This module implements a selector API with backends specific to each OS.
  Currently, epoll on Linux and select on other operating systems.

* `smtp <smtp.html>`_
  This module implements a simple SMTP client.

* `uri <uri.html>`_
  This module provides functions for working with URIs.


Threading
---------

* `threadpool <threadpool.html>`_
  Implements Nim's `spawn <manual_experimental.html#parallel-amp-spawn>`_.


Parsers
-------

* `htmlparser <htmlparser.html>`_
  This module parses an HTML document and creates its XML tree representation.

* `json <json.html>`_
  High-performance JSON parser.

* `jsonutils <jsonutils.html>`_
  This module implements a hookable (de)serialization for arbitrary types.

* `lexbase <lexbase.html>`_
  This is a low-level module that implements an extremely efficient buffering
  scheme for lexers and parsers. This is used by the diverse parsing modules.

* `parsecfg <parsecfg.html>`_
  The `parsecfg` module implements a high-performance configuration file
  parser. The configuration file's syntax is similar to the Windows ``.ini``
  format, but much more powerful, as it is not a line based parser. String
  literals, raw string literals, and triple quote string literals are supported
  as in the Nim programming language.

* `parsecsv <parsecsv.html>`_
  The `parsecsv` module implements a simple high-performance CSV parser.

* `parsejson <parsejson.html>`_
  This module implements a JSON parser. It is used and exported by the `json <json.html>`_ module, but can also be used in its own right.

* `parseopt <parseopt.html>`_
  The `parseopt` module implements a command line option parser.

* `parsesql <parsesql.html>`_
  The `parsesql` module implements a simple high-performance SQL parser.

* `parsexml <parsexml.html>`_
  The `parsexml` module implements a simple high performance XML/HTML parser.
  The only encoding that is supported is UTF-8. The parser has been designed
  to be somewhat error-correcting, so that even some "wild HTML" found on the
  web can be parsed with it.


Docutils
--------

* `packages/docutils/highlite <highlite.html>`_
  Source highlighter for programming or markup languages. Currently,
  only a few languages are supported, other languages may be added.
  The interface supports one language nested in another.

* `packages/docutils/rst <rst.html>`_
  This module implements a reStructuredText parser. A large subset
  is implemented. Some features of the markdown wiki syntax are also supported.

* `packages/docutils/rstast <rstast.html>`_
  This module implements an AST for the reStructuredText parser.

* `packages/docutils/rstgen <rstgen.html>`_
  This module implements a generator of HTML/Latex from reStructuredText.


XML Processing
--------------

* `xmltree <xmltree.html>`_
  A simple XML tree. More efficient and simpler than the DOM. It also
  contains a macro for XML/HTML code generation.

* `xmlparser <xmlparser.html>`_
  This module parses an XML document and creates its XML tree representation.


Generators
----------

* `htmlgen <htmlgen.html>`_
  This module implements a simple XML and HTML code
  generator. Each commonly used HTML tag has a corresponding macro
  that generates a string with its HTML representation.


Hashing
-------

* `base64 <base64.html>`_
  This module implements a Base64 encoder and decoder.

* `hashes <hashes.html>`_
  This module implements efficient computations of hash values for diverse
  Nim types.

* `md5 <md5.html>`_
  This module implements the MD5 checksum algorithm.

* `oids <oids.html>`_
  An OID is a global ID that consists of a timestamp,
  a unique counter, and a random value. This combination should suffice to
  produce a globally distributed unique ID. This implementation was extracted
  from the MongoDB interface and it thus binary compatible with a MongoDB OID.

* `sha1 <sha1.html>`_
  This module implements a sha1 encoder and decoder.


Miscellaneous
-------------

* `browsers <browsers.html>`_
  This module implements procs for opening URLs with the user's default
  browser.

* `colors <colors.html>`_
  This module implements color handling for Nim.

* `coro <coro.html>`_
  This module implements experimental coroutines in Nim.

* `enumerate <enumerate.html>`_
  This module implements `enumerate` syntactic sugar based on Nim's macro system.

* `logging <logging.html>`_
  This module implements a simple logger.

* `segfaults <segfaults.html>`_
  Turns access violations or segfaults into a `NilAccessDefect` exception.

* `sugar <sugar.html>`_
  This module implements nice syntactic sugar based on Nim's macro system.

* `unittest <unittest.html>`_
  Implements a Unit testing DSL.

* `varints <varints.html>`_
  Decode variable-length integers that are compatible with SQLite.

* `with <with.html>`_
  This module implements the `with` macro for easy function chaining.


Modules for the JS backend
--------------------------

* `asyncjs <asyncjs.html>`_
  Types and macros for writing asynchronous procedures in JavaScript.

* `dom <dom.html>`_
  Declaration of the Document Object Model for the JS backend.

* `jsbigints <jsbigints.html>`_
  Arbitrary precision integers.

* `jsconsole <jsconsole.html>`_
  Wrapper for the `console` object.

* `jscore <jscore.html>`_
  The wrapper of core JavaScript functions. For most purposes, you should be using
  the `math`, `json`, and `times` stdlib modules instead of this module.

* `jsffi <jsffi.html>`_
  Types and macros for easier interaction with JavaScript.


Impure libraries
================

Regular expressions
-------------------

* `re <re.html>`_
  This module contains procedures and operators for handling regular
  expressions. The current implementation uses PCRE.


Database support
----------------

* `db_postgres <db_postgres.html>`_
  A higher level PostgreSQL database wrapper. The same interface is implemented
  for other databases too.

* `db_mysql <db_mysql.html>`_
  A higher level MySQL database wrapper. The same interface is implemented
  for other databases too.

* `db_sqlite <db_sqlite.html>`_
  A higher level SQLite database wrapper. The same interface is implemented
  for other databases too.


Generic Operating System Services
---------------------------------

* `rdstdin <rdstdin.html>`_
  This module contains code for reading from stdin.


Wrappers
========

The generated HTML for some of these wrappers is so huge that it is
not contained in the distribution. You can then find them on the website.


Windows-specific
----------------

* `winlean <winlean.html>`_
  Contains a wrapper for a small subset of the Win32 API.
* `registry <registry.html>`_
  Windows registry support.


UNIX specific
-------------

* `posix <posix.html>`_
  Contains a wrapper for the POSIX standard.
* `posix_utils <posix_utils.html>`_
  Contains helpers for the POSIX standard or specialized for Linux and BSDs.


Regular expressions
-------------------

* `pcre <pcre.html>`_
  Wrapper for the PCRE library.


Database support
----------------

* `postgres <postgres.html>`_
  Contains a wrapper for the PostgreSQL API.
* `mysql <mysql.html>`_
  Contains a wrapper for the mySQL API.
* `sqlite3 <sqlite3.html>`_
  Contains a wrapper for the SQLite 3 API.
* `odbcsql <odbcsql.html>`_
  interface to the ODBC driver.


Network Programming and Internet Protocols
------------------------------------------

* `openssl <openssl.html>`_
  Wrapper for OpenSSL.
