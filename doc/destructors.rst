==================================
Nim Destructors and Move Semantics
==================================

:Authors: Andreas Rumpf
:Version: |nimversion|

.. contents::


About this document
===================

This document describes the upcoming Nim runtime which does
not use classical GC algorithms anymore but is based on destructors and
move semantics. The new runtime's advantages are that Nim programs become
oblivious to the involved heap sizes and programs are easier to write to make
effective use of multi-core machines. As a nice bonus, files and sockets and
the like will not require manual ``close`` calls anymore.

This document aims to be a precise specification about how
move semantics and destructors work in Nim.


Motivating example
==================

With the language mechanisms described here a custom seq could be
written as:

.. code-block:: nim

  type
    myseq*[T] = object
      len, cap: int
      data: ptr UncheckedArray[T]

  proc `=destroy`*[T](x: var myseq[T]) =
    if x.data != nil:
      for i in 0..<x.len: `=destroy`(x[i])
      dealloc(x.data)
      x.data = nil

  proc `=`*[T](a: var myseq[T]; b: myseq[T]) =
    # do nothing for self-assignments:
    if a.data == b.data: return
    `=destroy`(a)
    a.len = b.len
    a.cap = b.cap
    if b.data != nil:
      a.data = cast[type(a.data)](alloc(a.cap * sizeof(T)))
      for i in 0..<a.len:
        a.data[i] = b.data[i]

  proc `=sink`*[T](a: var myseq[T]; b: myseq[T]) =
    # move assignment
    `=destroy`(a)
    a.len = b.len
    a.cap = b.cap
    a.data = b.data

  proc add*[T](x: var myseq[T]; y: sink T) =
    if x.len >= x.cap: resize(x)
    x.data[x.len] = y
    inc x.len

  proc `[]`*[T](x: myseq[T]; i: Natural): lent T =
    assert i < x.len
    x.data[i]

  proc `[]=`*[T](x: var myseq[T]; i: Natural; y: sink T) =
    assert i < x.len
    x.data[i] = y

  proc createSeq*[T](elems: varargs[T]): myseq[T] =
    result.cap = elems.len
    result.len = elems.len
    result.data = cast[type(result.data)](alloc(result.cap * sizeof(T)))
    for i in 0..<result.len: result.data[i] = elems[i]

  proc len*[T](x: myseq[T]): int {.inline.} = x.len



Lifetime-tracking hooks
=======================

The memory management for Nim's standard ``string`` and ``seq`` types as
well as other standard collections is performed via so called
"Lifetime-tracking hooks" or "type-bound operators". There are 3 different
hooks for each (generic or concrete) object type ``T`` (``T`` can also be a
``distinct`` type) that are called implicitly by the compiler.

(Note: The word "hook" here does not imply any kind of dynamic binding
or runtime indirections, the implicit calls are statically bound and
potentially inlined.)


`=destroy` hook
---------------

A `=destroy` hook frees the object's associated memory and releases
other associated resources. Variables are destroyed via this hook when
they go out of scope or when the routine they were declared in is about
to return.

The prototype of this hook for a type ``T`` needs to be:

.. code-block:: nim

  proc `=destroy`(x: var T)


The general pattern in ``=destroy`` looks like:

.. code-block:: nim

  proc `=destroy`(x: var T) =
    # first check if 'x' was moved to somewhere else:
    if x.field != nil:
      freeResource(x.field)
      x.field = nil



`=sink` hook
------------

A `=sink` hook moves an object around, the resources are stolen from the source
and passed to the destination. It is ensured that source's destructor does
not free the resources afterwards by setting the object to its default value
(the value the object's state started in). Setting an object ``x`` back to its
default value is written as ``wasMoved(x)``.

The prototype of this hook for a type ``T`` needs to be:

.. code-block:: nim

  proc `=sink`(dest: var T; source: T)


The general pattern in ``=sink`` looks like:

.. code-block:: nim

  proc `=sink`(dest: var T; source: T) =
    `=destroy`(dest)
    dest.field = source.field


**Note**: ``=sink`` does not need to check for self-assignments.
How self-assignments are handled is explained later in this document.


`=` (copy) hook
---------------

The ordinary assignment in Nim conceptually copies the values. The ``=`` hook
is called for assignments that couldn't be transformed into ``=sink``
operations.

The prototype of this hook for a type ``T`` needs to be:

.. code-block:: nim

  proc `=`(dest: var T; source: T)


The general pattern in ``=`` looks like:

.. code-block:: nim

  proc `=`(dest: var T; source: T) =
    # protect against self-assignments:
    if dest.field != source.field:
      `=destroy`(dest)
      dest.field = duplicateResource(source.field)


The ``=`` proc can be marked with the ``{.error.}`` pragma. Then any assignment
that otherwise would lead to a copy is prevented at compile-time.


Move semantics
==============

A "move" can be regarded as an optimized copy operation. If the source of the
copy operation is not used afterwards, the copy can be replaced by a move. This
document uses the notation ``lastReadOf(x)`` to describe that ``x`` is not
used afterwards. This property is computed by a static control flow analysis
but can also be enforced by using ``system.move`` explicitly.


Swap
====

The need to check for self-assignments and also the need to destroy previous
objects inside ``=`` and ``=sink`` is a strong indicator to treat
``system.swap`` as a builtin primitive of its own that simply swaps every
field in the involved objects via ``copyMem`` or a comparable mechanism.
In other words, ``swap(a, b)`` is **not** implemented
as ``let tmp = move(a); b = move(a); a = move(tmp)``.

This has further consequences:

* Objects that contain pointers that point to the same object are not supported
  by Nim's model. Otherwise swapped objects would end up in an inconsistent state.
* Seqs can use ``realloc`` in the implementation.


Sink parameters
===============

To move a variable into a collection usually ``sink`` parameters are involved.
A location that is passed to a ``sink`` parameter should not be used afterwards.
This is ensured by a static analysis over a control flow graph. If it cannot be
proven to be the last usage of the location, a copy is done instead and this
copy is then passed to the sink parameter.

A sink parameter
*may* be consumed once in the proc's body but doesn't have to be consumed at all.
The reason for this is that signatures
like ``proc put(t: var Table; k: sink Key, v: sink Value)`` should be possible
without any further overloads and ``put`` might not take owership of ``k`` if
``k`` already exists in the table. Sink parameters enable an affine type system,
not a linear type system.

The employed static analysis is limited and only concerned with local variables;
however object and tuple fields are treated as separate entities:

.. code-block:: nim

  proc consume(x: sink Obj) = discard "no implementation"

  proc main =
    let tup = (Obj(), Obj())
    consume tup[0]
    # ok, only tup[0] was consumed, tup[1] is still alive:
    echo tup[1]


Sometimes it is required to explicitly ``move`` a value into its final position:

.. code-block:: nim

  proc main =
    var dest, src: array[10, string]
    # ...
    for i in 0..high(dest): dest[i] = move(src[i])

An implementation is allowed, but not required to implement even more move
optimizations (and the current implementation does not).



Rewrite rules
=============

**Note**: There are two different allowed implementation strategies:

1. The produced ``finally`` section can be a single section that is wrapped
   around the complete routine body.
2. The produced ``finally`` section is wrapped around the enclosing scope.

The current implementation follows strategy (1). This means that resources are
not destroyed at the scope exit, but at the proc exit.

::

  var x: T; stmts
  ---------------             (destroy-var)
  var x: T; try stmts
  finally: `=destroy`(x)


  g(f(...))
  ------------------------    (nested-function-call)
  g(let tmp;
  bitwiseCopy tmp, f(...);
  tmp)
  finally: `=destroy`(tmp)


  x = f(...)
  ------------------------    (function-sink)
  `=sink`(x, f(...))


  x = lastReadOf z
  ------------------          (move-optimization)
  `=sink`(x, z)
  wasMoved(z)


  v = v
  ------------------   (self-assignment-removal)
  discard "nop"


  x = y
  ------------------          (copy)
  `=`(x, y)


  f_sink(g())
  -----------------------     (call-to-sink)
  f_sink(g())


  f_sink(notLastReadOf y)
  --------------------------     (copy-to-sink)
  (let tmp; `=`(tmp, y);
  f_sink(tmp))


  f_sink(lastReadOf y)
  -----------------------     (move-to-sink)
  f_sink(y)
  wasMoved(y)


Object and array construction
=============================

Object and array construction is treated as a function call where the
function has ``sink`` parameters.


Destructor removal
==================

``wasMoved(x);`` followed by a `=destroy(x)` operation cancel each other
out. An implementation is encouraged to exploit this in order to improve
efficiency and code sizes.


Self assignments
================

``=sink`` in combination with ``wasMoved`` can handle self-assignments but
it's subtle.

The simple case of ``x = x`` cannot be turned
into ``=sink(x, x); wasMoved(x)`` because that would lose ``x``'s value.
The solution is that simple self-assignments are simply transformed into
an empty statement that does nothing.

The complex case looks like a variant of ``x = f(x)``, we consider
``x = select(rand() < 0.5, x, y)`` here:


.. code-block:: nim

  proc select(cond: bool; a, b: sink string): string =
    if cond:
      result = a # moves a into result
    else:
      result = b # moves b into result

  proc main =
    var x = "abc"
    var y = "xyz"
    # possible self-assignment:
    x = select(true, x, y)


Is transformed into:


.. code-block:: nim

  proc select(cond: bool; a, b: sink string): string =
    try:
      if cond:
        `=sink`(result, a)
        wasMoved(a)
      else:
        `=sink`(result, b)
        wasMoved(b)
    finally:
      `=destroy`(b)
      `=destroy`(a)

  proc main =
    var
      x: string
      y: string
    try:
      `=sink`(x, "abc")
      `=sink`(y, "xyz")
      `=sink`(x, select(true,
        let blitTmp = x
        wasMoved(x)
        blitTmp,
        let blitTmp = y
        wasMoved(y)
        blitTmp))
      echo [x]
    finally:
      `=destroy`(y)
      `=destroy`(x)

As can be manually verified, this transformation is correct for
self-assignments.


Lent type
=========

``proc p(x: sink T)`` means that the proc ``p`` takes ownership of ``x``.
To eliminate even more creation/copy <-> destruction pairs, a proc's return
type can be annotated as ``lent T``. This is useful for "getter" accessors
that seek to allow an immutable view into a container.

The ``sink`` and ``lent`` annotations allow us to remove most (if not all)
superfluous copies and destructions.

``lent T`` is like ``var T`` a hidden pointer. It is proven by the compiler
that the pointer does not outlive its origin. No destructor call is injected
for expressions of type ``lent T`` or of type ``var T``.


.. code-block:: nim

  type
    Tree = object
      kids: seq[Tree]

  proc construct(kids: sink seq[Tree]): Tree =
    result = Tree(kids: kids)
    # converted into:
    `=sink`(result.kids, kids); wasMoved(kids)

  proc `[]`*(x: Tree; i: int): lent Tree =
    result = x.kids[i]
    # borrows from 'x', this is transformed into:
    result = addr x.kids[i]
    # This means 'lent' is like 'var T' a hidden pointer.
    # Unlike 'var' this hidden pointer cannot be used to mutate the object.

  iterator children*(t: Tree): lent Tree =
    for x in t.kids: yield x

  proc main =
    # everything turned into moves:
    let t = construct(@[construct(@[]), construct(@[])])
    echo t[0] # accessor does not copy the element!



Owned refs
==========

Let ``W`` be an ``owned ref`` type. Conceptually its hooks look like:

.. code-block:: nim

  proc `=destroy`(x: var W) =
    if x != nil:
      assert x.refcount == 0, "dangling unowned pointers exist!"
      `=destroy`(x[])
      x = nil

  proc `=`(x: var W; y: W) {.error: "owned refs can only be moved".}

  proc `=sink`(x: var W; y: W) =
    `=destroy`(x)
    bitwiseCopy x, y # raw pointer copy


Let ``U`` be an unowned ``ref`` type. Conceptually its hooks look like:

.. code-block:: nim

  proc `=destroy`(x: var U) =
    if x != nil:
      dec x.refcount

  proc `=`(x: var U; y: U) =
    # Note: No need to check for self-assignments here.
    if y != nil: inc y.refcount
    if x != nil: dec x.refcount
    bitwiseCopy x, y # raw pointer copy

  proc `=sink`(x: var U, y: U) {.error.}
  # Note: Moves are not available.


Hook lifting
============

The hooks of a tuple type ``(A, B, ...)`` are generated by lifting the
hooks of the involved types ``A``, ``B``, ... to the tuple type. In
other words, a copy ``x = y`` is implemented
as ``x[0] = y[0]; x[1] = y[1]; ...``, likewise for ``=sink`` and ``=destroy``.

Other value-based compound types like ``object`` and ``array`` are handled
correspondingly. For ``object`` however, the compiler generated hooks
can be overridden. This can also be important to use an alternative traversal
of the involved datastructure that is more efficient or in order to avoid
deep recursions.



Hook generation
===============

The ability to override a hook leads to a phase ordering problem:

.. code-block:: nim

  type
    Foo[T] = object

  proc main =
    var f: Foo[int]
    # error: destructor for 'f' called here before
    # it was seen in this module.

  proc `=destroy`[T](f: var Foo[T]) =
    discard


The solution is to define ``proc `=destroy`[T](f: var Foo[T])`` before
it is used. The compiler generates implicit
hooks for all types in *strategic places* so that an explicitly provided
hook that comes too "late" can be detected reliably. These *strategic places*
have been derived from the rewrite rules and are as follows:

- In the construct ``let/var x = ...`` (var/let binding)
  hooks are generated for ``typeof(x)``.
- In ``x = ...`` (assignment) hooks are generated for ``typeof(x)``.
- In ``f(...)`` (function call) hooks are generated for ``typeof(f(...))``.
- For every sink parameter ``x: sink T`` the hooks are generated
  for ``typeof(x)``.


nodestroy pragma
================

The experimental `nodestroy`:idx: pragma inhibits hook injections. This can be
used to specialize the object traversal in order to avoid deep recursions:


.. code-block:: nim

  type Node = ref object
    x, y: int32
    left, right: owned Node

  type Tree = object
    root: owned Node

  proc `=destroy`(t: var Tree) {.nodestroy.} =
    # use an explicit stack so that we do not get stack overflows:
    var s: seq[owned Node] = @[t.root]
    while s.len > 0:
      let x = s.pop
      if x.left != nil: s.add(x.left)
      if x.right != nil: s.add(x.right)
      # free the memory explicit:
      dispose(x)
    # notice how even the destructor for 's' is not called implicitly
    # anymore thanks to .nodestroy, so we have to call it on our own:
    `=destroy`(s)


As can be seen from the example, this solution is hardly sufficient and
should eventually be replaced by a better solution.
