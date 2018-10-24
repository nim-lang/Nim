# Nim Standard Library

Author

:   Andreas Rumpf

Version

:   

::: {.contents}
\"The good thing about reinventing the wheel is that you can get a round one.\"
:::

Though the Nim Standard Library is still evolving, it is already quite usable.
It is divided into *pure libraries*, *impure libraries* and *wrappers*.

Pure libraries do not depend on any external `*.dll` or `lib*.so` binary while
impure libraries do. A wrapper is an impure library that is a very low-level
interface to a C library.

Read this [document](apis.html) for a quick overview of the API design.

In addition to the modules in the standard library, third-party packages created
by the Nim community can be used via [Nimble](#nimble), Nim\'s package manager.

## Pure libraries

### Core

-   [system](system.html) Basic procs and operators that every program needs. It
    also provides IO facilities for reading and writing text and binary files.
    It is imported implicitly by the compiler. Do not import it directly. It
    relies on compiler magic to work.
-   [threads](threads.html) Nim thread support. **Note**: This is part of the
    system module. Do not import it explicitly.
-   [channels](channels.html) Nim message passing support for threads. **Note**:
    This is part of the system module. Do not import it explicitly.
-   [locks](locks.html) Locks and condition variables for Nim.
-   [rlocks](rlocks.html) Reentrant locks for Nim.
-   [macros](macros.html) Contains the AST API and documentation of Nim for
    writing macros.
-   [typeinfo](typeinfo.html) Provides (unsafe) access to Nim\'s run time type
    information.
-   [typetraits](typetraits.html) This module defines compile-time reflection
    procs for working with types.
-   [threadpool](threadpool.html) Implements Nim\'s
    [spawn](manual.html#parallel-amp-spawn).
-   [cpuinfo](cpuinfo.html) This module implements procs to determine the number
    of CPUs / cores.
-   [lenientops](lenientops.html) Provides binary operators for mixed
    integer/float expressions for convenience.

### Collections and algorithms

-   [algorithm](algorithm.html) Implements some common generic algorithms like
    sort or binary search.
-   [tables](tables.html) Nim hash table support. Contains tables, ordered
    tables and count tables.
-   [sets](sets.html) Nim hash and bit set support.
-   [lists](lists.html) Nim linked list support. Contains singly and doubly
    linked lists and circular lists (\"rings\").
-   [deques](deques.html) Implementation of a double-ended queue. The underlying
    implementation uses a `seq`.
-   [intsets](intsets.html) Efficient implementation of a set of ints as a
    sparse bit set.
-   [critbits](critbits.html) This module implements a *crit bit tree* which is
    an efficient container for a sorted set of strings, or for a sorted mapping
    of strings.
-   [sequtils](sequtils.html) This module implements operations for the built-in
    seq type which were inspired by functional programming languages.
-   [sharedtables](sharedtables.html) Nim shared hash table support. Contains
    shared tables.
-   [sharedlist](sharedlist.html) Nim shared linked list support. Contains
    shared singly linked list.

### String handling

-   [strutils](strutils.html) This module contains common string handling
    operations like changing case of a string, splitting a string into
    substrings, searching for substrings, replacing substrings.
-   [strformat](strformat.html) Macro based standard string interpolation /
    formatting. Inpired by Python\'s `` `f ``-strings.
-   [strmisc](strmisc.html) This module contains uncommon string handling
    operations that do not fit with the commonly used operations in strutils.
-   [parseutils](parseutils.html) This module contains helpers for parsing
    tokens, numbers, identifiers, etc.
-   [strscans](strscans.html) This module contains a `scanf` macro for
    convenient parsing of mini languages.
-   [strtabs](strtabs.html) The `strtabs` module implements an efficient hash
    table that is a mapping from strings to strings. Supports a case-sensitive,
    case-insensitive and style-insensitive mode. An efficient string
    substitution operator `%` for the string table is also provided.
-   [unicode](unicode.html) This module provides support to handle the Unicode
    UTF-8 encoding.
-   [encodings](encodings.html) Converts between different character encodings.
    On UNIX, this uses the `iconv` library, on Windows the Windows API.
-   [pegs](pegs.html) This module contains procedures and operators for handling
    PEGs.
-   [ropes](ropes.html) This module contains support for a *rope* data type.
    Ropes can represent very long strings efficiently; especially concatenation
    is done in O(1) instead of O(n).
-   [matchers](matchers.html) This module contains various string matchers for
    email addresses, etc.
-   [subexes](subexes.html) This module implements advanced string substitution
    operations.
-   [editdistance](editdistance) This module contains an algorithm to compute
    the edit distance between two Unicode strings.

### Generic Operating System Services

-   [os](os.html) Basic operating system facilities like retrieving environment
    variables, reading command line arguments, working with directories, running
    shell commands, etc.
-   [osproc](osproc.html) Module for process communication beyond
    `os.execShellCmd`.
-   [times](times.html) The `times` module contains basic support for working
    with time.
-   [dynlib](dynlib.html) This module implements the ability to access symbols
    from shared libraries.
-   [streams](streams.html) This module provides a stream interface and two
    implementations thereof: the [FileStream]{.title-ref} and the
    [StringStream]{.title-ref} which implement the stream interface for Nim file
    objects ([File]{.title-ref}) and strings. Other modules may provide other
    implementations for this standard stream interface.
-   [marshal](marshal.html) Contains procs for serialization and deseralization
    of arbitrary Nim data structures.
-   [terminal](terminal.html) This module contains a few procedures to control
    the *terminal* (also called *console*). The implementation simply uses ANSI
    escape sequences and does not depend on any other module.
-   [memfiles](memfiles.html) This module provides support for memory mapped
    files (Posix\'s `mmap`) on the different operating systems.
-   [asyncfile](asyncfile.html) This module implements asynchronous file reading
    and writing using `asyncdispatch`.
-   [distros](distros.html) This module implements the basics for OS
    distribution (\"distro\") detection and the OS\'s native package manager.
    Its primary purpose is to produce output for Nimble packages, but it also
    contains the widely used **Distribution** enum that is useful for writing
    platform specific code.

### Math libraries

-   [math](math.html) Mathematical operations like cosine, square root.
-   [complex](complex.html) This module implements complex numbers and their
    mathematical operations.
-   [rationals](rationals.html) This module implements rational numbers and
    their mathematical operations.
-   [fenv](fenv.html) Floating-point environment. Handling of floating-point
    rounding and exceptions (overflow, zero-devide, etc.).
-   [mersenne](mersenne.html) Mersenne twister random number generator.
-   [random](random.html) Fast and tiny random number generator.
-   [stats](stats.html) Statistical analysis

### Internet Protocols and Support

-   [cgi](cgi.html) This module implements helpers for CGI applications.
-   [scgi](scgi.html) This module implements helpers for SCGI applications.
-   [browsers](browsers.html) This module implements procs for opening URLs with
    the user\'s default browser.
-   [httpclient](httpclient.html) This module implements a simple HTTP client
    which supports both synchronous and asynchronous retrieval of web pages.
-   [smtp](smtp.html) This module implement a simple SMTP client.
-   [cookies](cookies.html) This module contains helper procs for parsing and
    generating cookies.
-   [mimetypes](mimetypes.html) This module implements a mimetypes database.
-   [uri](uri.html) This module provides functions for working with URIs.
-   [asyncdispatch](asyncdispatch.html) This module implements an asynchronous
    dispatcher for IO operations.
-   [asyncnet](asyncnet.html) This module implements asynchronous sockets based
    on the `asyncdispatch` module.
-   [asynchttpserver](asynchttpserver.html) This module implements an
    asynchronous HTTP server using the `asyncnet` module.
-   [asyncftpclient](asyncftpclient.html) This module implements an asynchronous
    FTP client using the `asyncnet` module.
-   [net](net.html) This module implements a high-level sockets API. It will
    replace the `sockets` module in the future.
-   [nativesockets](nativesockets.html) This module implements a low-level
    sockets API.
-   [selectors](selectors.html) This module implements a selector API with
    backends specific to each OS. Currently epoll on Linux and select on other
    operating systems.

### Parsers

-   [parseopt](parseopt.html) The `parseopt` module implements a command line
    option parser.
-   [parsecfg](parsecfg.html) The `parsecfg` module implements a high
    performance configuration file parser. The configuration file\'s syntax is
    similar to the Windows `.ini` format, but much more powerful, as it is not a
    line based parser. String literals, raw string literals and triple quote
    string literals are supported as in the Nim programming language.
-   [parsexml](parsexml.html) The `parsexml` module implements a simple high
    performance XML/HTML parser. The only encoding that is supported is UTF-8.
    The parser has been designed to be somewhat error correcting, so that even
    some \"wild HTML\" found on the Web can be parsed with it.
-   [parsecsv](parsecsv.html) The `parsecsv` module implements a simple high
    performance CSV parser.
-   [parsesql](parsesql.html) The `parsesql` module implements a simple high
    performance SQL parser.
-   [json](json.html) High performance JSON parser.
-   [lexbase](lexbase.html) This is a low level module that implements an
    extremely efficient buffering scheme for lexers and parsers. This is used by
    the diverse parsing modules.
-   [highlite](highlite.html) Source highlighter for programming or markup
    languages. Currently only few languages are supported, other languages may
    be added. The interface supports one language nested in another.
-   [rst](rst.html) This module implements a reStructuredText parser. A large
    subset is implemented. Some features of the markdown wiki syntax are also
    supported.
-   [rstast](rstast.html) This module implements an AST for the reStructuredText
    parser.
-   [rstgen](rstgen.html) This module implements a generator of HTML/Latex from
    reStructuredText.
-   [sexp](sexp.html) High performance sexp parser and generator, mainly for
    communication with emacs.

### XML Processing

-   [xmltree](xmltree.html) A simple XML tree. More efficient and simpler than
    the DOM. It also contains a macro for XML/HTML code generation.
-   [xmlparser](xmlparser.html) This module parses an XML document and creates
    its XML tree representation.
-   [htmlparser](htmlparser.html) This module parses an HTML document and
    creates its XML tree representation.
-   [htmlgen](htmlgen.html) This module implements a simple XML and HTML code
    generator. Each commonly used HTML tag has a corresponding macro that
    generates a string with its HTML representation.

### Cryptography and Hashing

-   [hashes](hashes.html) This module implements efficient computations of hash
    values for diverse Nim types.
-   [md5](md5.html) This module implements the MD5 checksum algorithm.
-   [base64](base64.html) This module implements a base64 encoder and decoder.
-   [sha1](sha1.html) This module implements a sha1 encoder and decoder.

### Multimedia support

-   [colors](colors.html) This module implements color handling for Nim. It is
    used by the `graphics` module.

### Miscellaneous

-   [oids](oids.html) An OID is a global ID that consists of a timestamp, a
    unique counter and a random value. This combination should suffice to
    produce a globally distributed unique ID. This implementation was extracted
    from the Mongodb interface and it thus binary compatible with a Mongo OID.
-   [endians](endians.html) This module contains helpers that deal with
    different byte orders.
-   [logging](logging.html) This module implements a simple logger.
-   [options](options.html) Types which encapsulate an optional value.
-   [sugar](sugar.html) This module implements nice syntactic sugar based on
    Nim\'s macro system.
-   [coro](coro.html) This module implements experimental coroutines in Nim.
-   [unittest](unittest.html) Implements a Unit testing DSL.
-   [segfaults](segfaults.html) Turns access violations or segfaults into a
    `NilAccessError` exception.

### Modules for JS backend

-   [dom](dom.html) Declaration of the Document Object Model for the JS backend.
-   [jsffi](jsffi.html) Types and macros for easier interaction with JavaScript.
-   [asyncjs](asyncjs.html) Types and macros for writing asynchronous procedures
    in JavaScript.
-   [jscore](jscore.html) Wrapper of core JavaScript functions. For most
    purposes you should be using the `math`, `json`, and `times` stdlib modules
    instead of this module.

## Impure libraries

### Regular expressions

-   [re](re.html) This module contains procedures and operators for handling
    regular expressions. The current implementation uses PCRE.

### Database support

-   [db\_postgres](db_postgres.html) A higher level PostgreSQL database wrapper.
    The same interface is implemented for other databases too.
-   [db\_mysql](db_mysql.html) A higher level MySQL database wrapper. The same
    interface is implemented for other databases too.
-   [db\_sqlite](db_sqlite.html) A higher level SQLite database wrapper. The
    same interface is implemented for other databases too.

### Other

-   [ssl](ssl.html) This module provides an easy to use sockets-style Nim
    interface to the OpenSSL library.

## Wrappers

The generated HTML for some of these wrappers is so huge that it is not
contained in the distribution. You can then find them on the website.

### Windows specific

-   [winlean](winlean.html) Contains a wrapper for a small subset of the Win32
    API.

### UNIX specific

-   [posix](posix.html) Contains a wrapper for the POSIX standard.

### Regular expressions

-   [pcre](pcre.html) Wrapper for the PCRE library.

### GUI libraries

-   [iup](iup.html) Wrapper of the IUP GUI library.

### Database support

-   [postgres](postgres.html) Contains a wrapper for the PostgreSQL API.
-   [mysql](mysql.html) Contains a wrapper for the mySQL API.
-   [sqlite3](sqlite3.html) Contains a wrapper for SQLite 3 API.
-   [odbcsql](odbcsql.html) interface to the ODBC driver.

### Network Programming and Internet Protocols

-   [openssl](openssl.html) Wrapper for OpenSSL.

## Nimble

Nimble is a package manager for the Nim programming language. For instructions
on how to install Nimble packages see [its
README](https://github.com/nim-lang/nimble#readme).

To see a list of Nimble\'s packages, check out <https://nimble.directory/> or
the [packages repo](https://github.com/nim-lang/packages) on GitHub.
