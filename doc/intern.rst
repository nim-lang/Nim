=========================================
    Internals of the Nim Compiler
=========================================


:Author: Andreas Rumpf
:Version: |nimversion|

.. default-role:: code
.. include:: rstcommon.rst
.. contents::

  "Abstraction is layering ignorance on top of reality." -- Richard Gabriel


Directory structure
===================

The Nim project's directory structure is:

============   ===================================================
Path           Purpose
============   ===================================================
`bin`          generated binary files
`build`        generated C code for the installation
`compiler`     the Nim compiler itself; note that this
               code has been translated from a bootstrapping
               version written in Pascal, so the code is **not**
               a poster child of good Nim code
`config`       configuration files for Nim
`dist`         additional packages for the distribution
`doc`          the documentation; it is a bunch of
               reStructuredText files
`lib`          the Nim library
============   ===================================================


Bootstrapping the compiler
==========================

**Note**: Add ``.`` to your PATH so that `koch`:cmd: can be used without the ``./``.

Compiling the compiler is a simple matter of running:

.. code:: cmd

  nim c koch.nim
  koch boot -d:release

For a debug version use:

.. code:: cmd

  nim c koch.nim
  koch boot


And for a debug version compatible with GDB:

.. code:: cmd

  nim c koch.nim
  koch boot --debuginfo --linedir:on

The `koch`:cmd: program is Nim's maintenance script. It is a replacement for
make and shell scripting with the advantage that it is much more portable.
More information about its options can be found in the `koch <koch.html>`_
documentation.


Reproducible builds
-------------------

Set the compilation timestamp with the `SOURCE_DATE_EPOCH` environment variable.

.. code:: cmd

  export SOURCE_DATE_EPOCH=$(git log -n 1 --format=%at)
  koch boot # or `./build_all.sh`


Developing the compiler
=======================

To create a new compiler for each run, use `koch temp`:cmd:\:

.. code:: cmd

  koch temp c test.nim

`koch temp`:cmd: creates a debug build of the compiler, which is useful
to create stacktraces for compiler debugging.

You can of course use GDB or Visual Studio to debug the
compiler (via `--debuginfo --lineDir:on`:option:). However, there
are also lots of procs that aid in debugging:


.. code-block:: nim

  # dealing with PNode:
  echo renderTree(someNode)
  debug(someNode) # some JSON representation

  # dealing with PType:
  echo typeToString(someType)
  debug(someType)

  # dealing with PSym:
  echo symbol.name.s
  debug(symbol)

  # pretty prints the Nim ast, but annotates symbol IDs:
  echo renderTree(someNode, {renderIds})
  if `??`(conf, n.info, "temp.nim"):
    # only output when it comes from "temp.nim"
    echo renderTree(n)
  if `??`(conf, n.info, "temp.nim"):
    # why does it process temp.nim here?
    writeStackTrace()

These procs may not already be imported by the module you're editing.
You can import them directly for debugging:

.. code-block:: nim
  from astalgo import debug
  from types import typeToString
  from renderer import renderTree
  from msgs import `??`


The compiler's architecture
===========================

Nim uses the classic compiler architecture: A lexer/scanner feeds tokens to a
parser. The parser builds a syntax tree that is used by the code generators.
This syntax tree is the interface between the parser and the code generator.
It is essential to understand most of the compiler's code.

Semantic analysis is separated from parsing.

.. include:: filelist.txt


The syntax tree
---------------
The syntax tree consists of nodes which may have an arbitrary number of
children. Types and symbols are represented by other nodes, because they
may contain cycles. The AST changes its shape after semantic checking. This
is needed to make life easier for the code generators. See the "ast" module
for the type definitions. The `macros <macros.html>`_ module contains many
examples how the AST represents each syntactic structure.


Bisecting for regressions
=========================

`koch temp`:cmd: returns 125 as the exit code in case the compiler
compilation fails. This exit code tells `git bisect`:cmd: to skip the
current commit:

.. code:: cmd

  git bisect start bad-commit good-commit
  git bisect run ./koch temp -r c test-source.nim

You can also bisect using custom options to build the compiler, for example if
you don't need a debug version of the compiler (which runs slower), you can replace
`./koch temp`:cmd: by explicit compilation command, see `Rebuilding the compiler`_.


Runtimes
========

Nim has two different runtimes, the "old runtime" and the "new runtime". The old
runtime supports the old GCs (markAndSweep, refc, Boehm), the new runtime supports
ARC/ORC. The new runtime is active `when defined(nimV2)`.


Coding Guidelines
=================

* We follow Nim's official style guide, see `<nep1.html>`_.
* Max line length is 100 characters.
* Provide spaces around binary operators if that enhances readability.
* Use a space after a colon, but not before it.
* [deprecated] Start types with a capital `T`, unless they are
  pointers/references which start with `P`.

See also the `API naming design <apis.html>`_ document.


Porting to new platforms
========================

Porting Nim to a new architecture is pretty easy, since C is the most
portable programming language (within certain limits) and Nim generates
C code, porting the code generator is not necessary.

POSIX-compliant systems on conventional hardware are usually pretty easy to
port: Add the platform to `platform` (if it is not already listed there),
check that the OS, System modules work and recompile Nim.

The only case where things aren't as easy is when old runtime's garbage
collectors need some assembler tweaking to work. The default
implementation uses C's `setjmp`:c: function to store all registers
on the hardware stack. It may be necessary that the new platform needs to
replace this generic code by some assembler code.


Runtime type information
========================

**Note**: This section describes the "old runtime".

*Runtime type information* (RTTI) is needed for several aspects of the Nim
programming language:

Garbage collection
  The old GCs use the RTTI for traversing abitrary Nim types, but usually
  only the `marker` field which contains a proc that does the traversal.

Complex assignments
  Sequences and strings are implemented as
  pointers to resizeable buffers, but Nim requires copying for
  assignments. Apart from RTTI the compiler also generates copy procedures
  as a specialization.

We already know the type information as a graph in the compiler.
Thus we need to serialize this graph as RTTI for C code generation.
Look at the file ``lib/system/hti.nim`` for more information.


Magics and compilerProcs
========================

The `system` module contains the part of the RTL which needs support by
compiler magic. The C code generator generates the C code for it, just like any other
module. However, calls to some procedures like `addInt` are inserted by
the generator. Therefore there is a table (`compilerprocs`)
with all symbols that are marked as `compilerproc`. `compilerprocs` are
needed by the code generator. A `magic` proc is not the same as a
`compilerproc`: A `magic` is a proc that needs compiler magic for its
semantic checking, a `compilerproc` is a proc that is used by the code
generator.


Code generation for closures
============================

Code generation for closures is implemented by `lambda lifting`:idx:.


Design
------

A `closure` proc var can call ordinary procs of the default Nim calling
convention. But not the other way round! A closure is implemented as a
`tuple[prc, env]`. `env` can be nil implying a call without a closure.
This means that a call through a closure generates an `if` but the
interoperability is worth the cost of the `if`. Thunk generation would be
possible too, but it's slightly more effort to implement.

Tests with GCC on Amd64 showed that it's really beneficial if the
'environment' pointer is passed as the last argument, not as the first argument.

Proper thunk generation is harder because the proc that is to wrap
could stem from a complex expression:

.. code-block:: nim
  receivesClosure(returnsDefaultCC[i])

A thunk would need to call 'returnsDefaultCC[i]' somehow and that would require
an *additional* closure generation... Ok, not really, but it requires to pass
the function to call. So we'd end up with 2 indirect calls instead of one.
Another much more severe problem which this solution is that it's not GC-safe
to pass a proc pointer around via a generic `ref` type.


Example code:

.. code-block:: nim
  proc add(x: int): proc (y: int): int {.closure.} =
    return proc (y: int): int =
      return x + y

  var add2 = add(2)
  echo add2(5) #OUT 7

This should produce roughly this code:

.. code-block:: nim
  type
    Env = ref object
      x: int # data

  proc anon(y: int, c: Env): int =
    return y + c.x

  proc add(x: int): tuple[prc, data] =
    var env: Env
    new env
    env.x = x
    result = (anon, env)

  var add2 = add(2)
  let tmp = if add2.data == nil: add2.prc(5) else: add2.prc(5, add2.data)
  echo tmp


Beware of nesting:

.. code-block:: nim
  proc add(x: int): proc (y: int): proc (z: int): int {.closure.} {.closure.} =
    return lambda (y: int): proc (z: int): int {.closure.} =
      return lambda (z: int): int =
        return x + y + z

  var add24 = add(2)(4)
  echo add24(5) #OUT 11

This should produce roughly this code:

.. code-block:: nim
  type
    EnvX = ref object
      x: int # data

    EnvY = ref object
      y: int
      ex: EnvX

  proc lambdaZ(z: int, ey: EnvY): int =
    return ey.ex.x + ey.y + z

  proc lambdaY(y: int, ex: EnvX): tuple[prc, data: EnvY] =
    var ey: EnvY
    new ey
    ey.y = y
    ey.ex = ex
    result = (lambdaZ, ey)

  proc add(x: int): tuple[prc, data: EnvX] =
    var ex: EnvX
    ex.x = x
    result = (labmdaY, ex)

  var tmp = add(2)
  var tmp2 = tmp.fn(4, tmp.data)
  var add24 = tmp2.fn(4, tmp2.data)
  echo add24(5)


We could get rid of nesting environments by always inlining inner anon procs.
More useful is escape analysis and stack allocation of the environment,
however.


Accumulator
-----------

.. code-block:: nim

  proc getAccumulator(start: int): proc (): int {.closure} =
    var i = start
    return lambda: int =
      inc i
      return i

  proc p =
    var delta = 7
    proc accumulator(start: int): proc(): int =
      var x = start-1
      result = proc (): int =
        x = x + delta
        inc delta
        return x

    var a = accumulator(3)
    var b = accumulator(4)
    echo a() + b()


Internals
---------

Lambda lifting is implemented as part of the `transf` pass. The `transf`
pass generates code to setup the environment and to pass it around. However,
this pass does not change the types! So we have some kind of mismatch here; on
the one hand the proc expression becomes an explicit tuple, on the other hand
the tyProc(ccClosure) type is not changed. For C code generation it's also
important the hidden formal param is `void*`:c: and not something more
specialized. However the more specialized env type needs to passed to the
backend somehow. We deal with this by modifying `s.ast[paramPos]` to contain
the formal hidden parameter, but not `s.typ`!


Notes on type and AST representation
====================================

To be expanded.


Integer literals
----------------

In Nim, there is a redundant way to specify the type of an
integer literal. First of all, it should be unsurprising that every
node has a node kind. The node of an integer literal can be any of the
following values::

    nkIntLit, nkInt8Lit, nkInt16Lit, nkInt32Lit, nkInt64Lit,
    nkUIntLit, nkUInt8Lit, nkUInt16Lit, nkUInt32Lit, nkUInt64Lit

On top of that, there is also the `typ` field for the type. It the
kind of the `typ` field can be one of the following ones, and it
should be matching the literal kind::

    tyInt, tyInt8, tyInt16, tyInt32, tyInt64, tyUInt, tyUInt8,
    tyUInt16, tyUInt32, tyUInt64

Then there is also the integer literal type. This is a specific type
that is implicitly convertible into the requested type if the
requested type can hold the value. For this to work, the type needs to
know the concrete value of the literal. For example an expression
`321` will be of type `int literal(321)`. This type is implicitly
convertible to all integer types and ranges that contain the value
`321`. That would be all builtin integer types except `uint8` and
`int8` where `321` would be out of range. When this literal type is
assigned to a new `var` or `let` variable, it's type will be resolved
to just `int`, not `int literal(321)` unlike constants. A constant
keeps the full `int literal(321)` type. Here is an example where that
difference matters.


.. code-block:: nim

   proc foo(arg: int8) =
     echo "def"

   const tmp1 = 123
   foo(tmp1)  # OK

   let tmp2 = 123
   foo(tmp2) # Error

In a context with multiple overloads, the integer literal kind will
always prefer the `int` type over all other types. If none of the
overloads is of type `int`, then there will be an error because of
ambiguity.

.. code-block:: nim

   proc foo(arg: int) =
     echo "abc"
   proc foo(arg: int8) =
     echo "def"
   foo(123) # output: abc

   proc bar(arg: int16) =
     echo "abc"
   proc bar(arg: int8) =
     echo "def"

   bar(123) # Error ambiguous call

In the compiler these integer literal types are represented with the
node kind `nkIntLit`, type kind `tyInt` and the member `n` of the type
pointing back to the integer literal node in the ast containing the
integer value. These are the properties that hold true for integer
literal types.

::
    n.kind == nkIntLit
    n.typ.kind == tyInt
    n.typ.n == n

Other literal types, such as `uint literal(123)` that would
automatically convert to other integer types, but prefers to
become a `uint` are not part of the Nim language.

In an unchecked AST, the `typ` field is nil. The type checker will set
the `typ` field accordingly to the node kind. Nodes of kind `nkIntLit`
will get the integer literal type (e.g. `int literal(123)`). Nodes of
kind `nkUIntLit` will get type `uint` (kind `tyUint`), etc.

This also means that it is not possible to write a literal in an
unchecked AST that will after sem checking just be of type `int` and
not implicitly convertible to other integer types. This only works for
all integer types that are not `int`.
