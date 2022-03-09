================
Not a Nim Manual
================

:Authors: Andreas Rumpf, Zahary Karadjov
:Version: |nimversion|

.. role:: nim(code)
   :language: nim
.. default-role:: nim

.. contents::


  "Complexity" seems to be a lot like "energy": you can transfer it from the
  end-user to one/some of the other players, but the total amount seems to remain
  pretty much constant for a given task. -- Ran


About this document
===================

**Note**: This document is a draft! Several of Nim's features may need more
precise wording. This manual is constantly evolving into a proper specification.

**Note**: The experimental features of Nim are
covered `here <manual_experimental.html>`_.

**Note**: Assignments, moves, and destruction are specified in
the `destructors <destructors.html>`_ document.

The language constructs are explained using an extended BNF, in which ``(a)*``
means 0 or more ``a``'s, ``a+`` means 1 or more ``a``'s, and ``(a)?`` means an
optional *a*. Parentheses may be used to group elements.

``&`` is the lookahead operator; ``&a`` means that an ``a`` is expected but
not consumed. It will be consumed in the following rule.

Non-terminals start with a lowercase letter, abstract terminal symbols are in
UPPERCASE. Verbatim terminal symbols (including keywords) are quoted
with ``'``. An example::

  ifStmt = 'if' expr ':' stmts ('elif' expr ':' stmts)* ('else' stmts)?

In a typical Nim program, most of the code is compiled into the executable.
However, some of the code may be executed at
`compile-time`:idx:. This can include constant expressions, macro definitions,
and Nim procedures used by macro definitions. Most of the Nim language is
supported at compile-time, but there are some restrictions -- see `Restrictions
on Compile-Time Execution <#restrictions-on-compileminustime-execution>`_ for
details. We use the term `runtime`:idx: to cover both compile-time execution
and code execution in the executable.

.. code-block:: nim
  var a: array[0..1, char]
  let i = 5
  try:
    a[i] = 'N'
  except IndexDefect:
    echo "invalid index"

Encoding
--------

All Nim source files are in the UTF-8 encoding (or its ASCII subset). Other
encodings are not supported. Any of the standard platform line termination
sequences can be used - the Unix form using ASCII LF (linefeed), the Windows
form using the ASCII sequence CR LF (return followed by linefeed), or the old
Macintosh form using the ASCII CR (return) character. All of these forms can be
used equally, regardless of the platform.


Indentation
-----------

Nim's standard grammar describes an `indentation sensitive`:idx: language.
This means that all the control structures are recognized by indentation.
Indentation consists only of spaces; tabulators are not allowed.

With this notation we can now easily define the core of the grammar: A block of
statements (simplified example)::

  ifStmt = 'if' expr ':' stmt
           (IND{=} 'elif' expr ':' stmt)*
           (IND{=} 'else' ':' stmt)?

  simpleStmt = ifStmt / ...

  stmt = IND{>} stmt ^+ IND{=} DED  # list of statements
       / simpleStmt                 # or a simple statement


String literals can be delimited by matching double quotes, and can
contain the following `escape sequences`:idx:\ :

==================         ===================================================
  Escape sequence          Meaning
==================         ===================================================
  ``\p``                   platform specific newline: CRLF on Windows,
                           LF on Unix
  ``\r``, ``\c``           `carriage return`:idx:
  ``\n``, ``\l``           `line feed`:idx: (often called `newline`:idx:)
  ``\f``                   `form feed`:idx:
  ``\t``                   `tabulator`:idx:
  ``\v``                   `vertical tabulator`:idx:
  ``\\``                   `backslash`:idx:
  ``\"``                   `quotation mark`:idx:
  ``\'``                   `apostrophe`:idx:
  ``\`` '0'..'9'+          `character with decimal value d`:idx:;
                           all decimal digits directly
                           following are used for the character
  ``\a``                   `alert`:idx:
  ``\b``                   `backspace`:idx:
  ``\e``                   `escape`:idx: `[ESC]`:idx:
  ``\x`` HH                `character with hex value HH`:idx:;
                           exactly two hex digits are allowed
  ``\u`` HHHH              `unicode codepoint with hex value HHHH`:idx:;
                           exactly four hex digits are allowed
  ``\u`` {H+}              `unicode codepoint`:idx:;
                           all hex digits enclosed in ``{}`` are used for
                           the codepoint
==================         ===================================================

.. code-block:: nim
  """"long string within quotes""""

Produces::

  "long string within quotes"

Operators
---------

Nim allows user defined operators. An operator is any combination of the
following characters::

       =     +     -     *     /     <     >
       @     $     ~     &     %     |
       !     ?     ^     .     :     \

(The grammar uses the terminal OPR to refer to operator symbols as
defined here.)

The following strings denote other tokens::

    `   (    )     {    }     [    ]    ,  ;   [.    .]  {.   .}  (.  .)  [:


Otherwise, precedence is determined by the first character.

================  =======================================================  ==================  ===============
Precedence level    Operators                                              First character     Terminal symbol
================  =======================================================  ==================  ===============
 10 (highest)                                                              ``$  ^``            OP10
  9               ``*    /    div   mod   shl  shr  %``                    ``*  %  \  /``      OP9
  8               ``+    -``                                               ``+  -  ~  |``      OP8
  7               ``&``                                                    ``&``               OP7
  6               ``..``                                                   ``.``               OP6
  5               ``==  <= < >= > !=  in notin is isnot not of as from``   ``=  <  >  !``      OP5
  4               ``and``                                                                      OP4
  3               ``or xor``                                                                   OP3
  2                                                                        ``@  :  ?``         OP2
  1               *assignment operator* (like ``+=``, ``*=``)                                  OP1
  0 (lowest)      *arrow like operator* (like ``->``, ``=>``)                                  OP0
================  =======================================================  ==================  ===============


Constants and Constant Expressions
==================================

A `constant`:idx: is a symbol that is bound to the value of a constant
expression. Constant expressions are restricted to depend only on the following
categories of values and operations, because these are either built into the
language or declared and evaluated before semantic analysis of the constant
expression:

* literals
* built-in operators
* previously declared constants and compile-time variables
* previously declared macros and templates
* previously declared procedures that have no side effects beyond
  possibly modifying compile-time variables

These integer types are pre-defined:

``int``
  the generic signed integer type; its size is platform-dependent and has the
  same size as a pointer. This type should be used in general. An integer
  literal that has no type suffix is of this type if it is in the range
  ``low(int32)..high(int32)`` otherwise the literal's type is ``int64``.

intXX
  additional signed integer types of XX bits use this naming scheme
  (example: int16 is a 16-bit wide integer).
  The current implementation supports ``int8``, ``int16``, ``int32``, ``int64``.
  Literals of these types have the suffix 'iXX.

``uint``
  the generic `unsigned integer`:idx: type; its size is platform-dependent and has the same size as a pointer. An integer literal with the type suffix ``'u`` is of this type.

Let ``T``'s be ``p``'s return type. NRVO applies for ``T``
if ``sizeof(T) >= N`` (where ``N`` is implementation dependent),
in other words, it applies for "big" structures.

Apart from built-in operations like array indexing, memory allocation, etc.
the ``raise`` statement is the only way to raise an exception.

.. XXX document this better!

`typedesc` used as a parameter type also introduces an implicit
generic. `typedesc` has its own set of rules:

The ``!=``, ``>``, ``>=``, ``in``, ``notin``, ``isnot`` operators are in fact
templates:

| ``a > b`` is transformed into ``b < a``.
| ``a in b`` is transformed into ``contains(b, a)``.
| ``notin`` and ``isnot`` have the obvious meanings.

A template where every parameter is ``untyped`` is called an `immediate`:idx:
template. For historical reasons templates can be explicitly annotated with
an ``immediate`` pragma and then these templates do not take part in
overloading resolution and the parameters' types are *ignored* by the
compiler. Explicit immediate templates are now deprecated.



Symbol lookup in generics
-------------------------

Open and Closed symbols
~~~~~~~~~~~~~~~~~~~~~~~

The symbol binding rules in generics are slightly subtle: There are "open" and
"closed" symbols. A "closed" symbol cannot be re-bound in the instantiation
context, an "open" symbol can. Per default overloaded symbols are open
and every other symbol is closed.

In templates identifiers can be constructed with the backticks notation:

.. code-block:: nim
    :test: "nim c $1"

  template typedef(name: untyped, typ: typedesc) =
    type
      `T name`* {.inject.} = typ
      `P name`* {.inject.} = ref `T name`

  typedef(myint, int)
  var x: PMyInt

In the example ``name`` is instantiated with ``myint``, so \`T name\` becomes
``Tmyint``.

Only top-level symbols that are marked with an asterisk (``*``) are
exported.

The algorithm for compiling modules is:

- compile the whole module as usual, following import statements recursively

- if there is a cycle only import the already parsed symbols (that are
  exported); if an unknown identifier occurs then abort


Collective imports from a directory
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The syntax ``import dir / [moduleA, moduleB]`` can be used to import multiple modules
from the same directory.


Pragmas
=======

Pragmas are Nim's method to give the compiler additional information /
commands without introducing a massive number of new keywords. Pragmas are
processed on the fly during semantic checking. Pragmas are enclosed in the
special ``{.`` and ``.}`` curly brackets. Pragmas are also often used as a
first implementation to play with a language feature before a nicer syntax
to access the feature becomes available.


deprecated pragma
-----------------

The deprecated pragma is used to mark a symbol as deprecated:

**Note**: `c2nim <https://github.com/nim-lang/c2nim/blob/master/doc/c2nim.rst>`_ can parse a large subset of C++ and knows
about the ``importcpp`` pragma pattern language. It is not necessary
to know all the details described here.



Pure libraries do not depend on any external ``*.dll`` or ``lib*.so`` binary
while impure libraries do. A wrapper is an impure library that is a very
low-level interface to a C library.


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
  Basic Nim thread support. **Note**: This is part of the system module. Do not
  import it explicitly. Enabled with ``--threads:on``.

Code reordering
===============

The code reordering feature can implicitly rearrange procedure, template, and
macro definitions along with variable declarations and initializations at the top
level scope so that, to a large extent, a programmer should not have to worry
about ordering definitions correctly or be forced to use forward declarations to
preface definitions inside a module.

..
   NOTE: The following was documentation for the code reordering precursor,
   which was {.noForward.}.

   In this mode, procedure definitions may appear out of order and the compiler
   will postpone their semantic analysis and compilation until it actually needs
   to generate code using the definitions. In this regard, this mode is similar
   to the modus operandi of dynamic scripting languages, where the function
   calls are not resolved until the code is executed. Here is the detailed
   algorithm taken by the compiler:

   1. When a callable symbol is first encountered, the compiler will only note
   the symbol callable name and it will add it to the appropriate overload set
   in the current scope. At this step, it won't try to resolve any of the type
   expressions used in the signature of the symbol (so they can refer to other
   not yet defined symbols).

   2. When a top level call is encountered (usually at the very end of the
   module), the compiler will try to determine the actual types of all of the
   symbols in the matching overload set. This is a potentially recursive process
   as the signatures of the symbols may include other call expressions, whose
   types will be resolved at this point too.

   3. Finally, after the best overload is picked, the compiler will start
   compiling the body of the respective symbol. This in turn will lead the
   compiler to discover more call expressions that need to be resolved and steps
   2 and 3 will be repeated as necessary.

   Please note that if a callable symbol is never used in this scenario, its
   body will never be compiled. This is the default behavior leading to best
   compilation times, but if exhaustive compilation of all definitions is
   required, using ``nim check`` provides this option as well.

Example:

.. code-block:: nim

  {.experimental: "codeReordering".}

  proc foo(x: int) =
    bar(x)

  proc bar(x: int) =
    echo(x)

  foo(10)


..
   TODO: Let's table this for now. This is an *experimental feature* and so the
   specific manner in which ``declared`` operates with it can be decided in
   eventuality, because right now it works a bit weirdly.

   The values of expressions involving ``declared`` are decided *before* the
   code reordering process, and not after. As an example, the output of this
   code is the same as it would be with code reordering disabled.

   .. code-block:: nim
     {.experimental: "codeReordering".}

     proc x() =
       echo(declared(foo))

     var foo = 4

     x() # "false"

It is important to note that reordering *only* works for symbols at top level
scope. Therefore, the following will *fail to compile:*


Parameter constraints
---------------------

The `parameter constraint`:idx: expression can use the operators ``|`` (or),
``&`` (and) and ``~`` (not) and the following predicates:


The ``~`` operator
~~~~~~~~~~~~~~~~~~

The ``~`` operator is the **not** operator in patterns:


The ``**`` operator
~~~~~~~~~~~~~~~~~~~

The ``**`` is much like the ``*`` operator, except that it gathers not only
all the arguments, but also the matched operators in reverse polish notation:

Nim significantly improves on the safety of these features via additional
pragmas:

1) A `guard`:idx: annotation is introduced to prevent data races.
2) Every access of a guarded memory location needs to happen in an
   appropriate `locks`:idx: statement.
3) Locks and routines can be annotated with `lock levels`:idx: to allow
   potential deadlocks to be detected during semantic analysis.

1. Two output parameters should never be aliased.
2. An input and an output parameter should not be aliased.
3. An output parameter should never be aliased with a global or thread local
   variable referenced by the called proc.
4. An input parameter should not be aliased with a global or thread local
   variable updated by the called proc.

One problem with rules 3 and 4 is that they affect specific global or thread
local variables, but Nim's effect tracking only tracks "uses no global variable"
via ``.noSideEffect``. The rules 3 and 4 can also be approximated by a different rule:

5. A global or thread local variable (or a location derived from such a location)
   can only passed to a parameter of a ``.noSideEffect`` proc.

These two procs are the two modus operandi of the real-time garbage collector:

(1) GC_SetMaxPause Mode

    You can call ``GC_SetMaxPause`` at program startup and then each triggered
    garbage collector run tries to not take longer than ``maxPause`` time. However, it is
    possible (and common) that the work is nevertheless not evenly distributed
    as each call to ``new`` can trigger the garbage collector and thus take  ``maxPause``
    time.

(2) GC_step Mode

    This allows the garbage collector to perform some work for up to ``us`` time.
    This is useful to call in the main loop to ensure the garbage collector can do its work.
    To bind all garbage collector activity to a ``GC_step`` call,
    deactivate the garbage collector with ``GC_disable`` at program startup.
    If ``strongAdvice`` is set to ``true``,
    then the garbage collector will be forced to perform the collection cycle.
    Otherwise, the garbage collector may decide not to do anything,
    if there is not much garbage to collect.
    You may also specify the current stack size via ``stackSize`` parameter.
    It can improve performance when you know that there are no unique Nim references
    below a certain point on the stack. Make sure the size you specify is greater
    than the potential worst-case size.

    It can improve performance when you know that there are no unique Nim
    references below a certain point on the stack. Make sure the size you specify
    is greater than the potential worst-case size.

These procs provide a "best effort" real-time guarantee; in particular the
cycle collector is not aware of deadlines. Deactivate it to get more
predictable real-time behaviour. Tests show that a 1ms max pause
time will be met in almost all cases on modern CPUs (with the cycle collector
disabled).

Time measurement with garbage collectors
----------------------------------------

The garbage collectors' way of measuring time uses
(see ``lib/system/timers.nim`` for the implementation):

1) ``QueryPerformanceCounter`` and ``QueryPerformanceFrequency`` on Windows.
2) ``mach_absolute_time`` on Mac OS X.
3) ``gettimeofday`` on Posix systems.

As such it supports a resolution of nanoseconds internally; however, the API
uses microseconds for convenience.

Introduction
============

.. raw:: html
  <blockquote><p>
  "Der Mensch ist doch ein Augentier -- sch&ouml;ne Dinge w&uuml;nsch ich mir."
  </p></blockquote>


This document is a tutorial for the programming language *Nim*.
This tutorial assumes that you are familiar with basic programming concepts
like variables, types, or statements but is kept very basic. The `manual
<manual.html>`_ contains many more examples of the advanced language features.
All code examples in this tutorial, as well as the ones found in the rest of
Nim's documentation, follow the `Nim style guide <nep1.html>`_.

However, this does not work. The problem is that the procedure should not
only ``return``, but return and **continue** after an iteration has
finished. This *return and continue* is called a `yield` statement. Now
the only thing left to do is to replace the ``proc`` keyword by ``iterator``
and here it is - our first iterator:

| A1 header    | A2 \| not fooled
| :---         | ----:       |
| C1           | C2 **bold** | ignored |
| D1 `code \|` | D2          | also ignored
| E1 \| text   |
|              | F2 without pipe
not in table
