==================================
Nim析构函数与移动语义
==================================

:Authors: Andreas Rumpf
:Version: |nimversion|

.. contents::


关于本文档
===================

本文档描述了即将推出的Nim运行时，它不再使用经典的GC算法，而是基于析构函数和移动语义。
新运行时的优点是Nim程序无法访问所涉及的堆大小，并且程序更易于编写以有效使用多核机器。
作为一个很好的奖励，文件和套接字等不再需要手动“关闭”调用。

本文档旨在成为关于Nim中移动语义和析构函数如何工作的精确规范。


起因示例
==================

使用此处描述的语言机制，自定义seq可以写为：

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
    # 自赋值不做任何事:
    if a.data == b.data: return
    `=destroy`(a)
    a.len = b.len
    a.cap = b.cap
    if b.data != nil:
      a.data = cast[type(a.data)](alloc(a.cap * sizeof(T)))
      for i in 0..<a.len:
        a.data[i] = b.data[i]

  proc `=sink`*[T](a: var myseq[T]; b: myseq[T]) =
    # 移动赋值
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

  proc `[]=`*[T](x: myseq[T]; i: Natural; y: sink T) =
    assert i < x.len
    x.data[i] = y

  proc createSeq*[T](elems: varargs[T]): myseq[T] =
    result.cap = elems.len
    result.len = elems.len
    result.data = cast[type(result.data)](alloc(result.cap * sizeof(T)))
    for i in 0..<result.len: result.data[i] = elems[i]

  proc len*[T](x: myseq[T]): int {.inline.} = x.len



生命周期跟踪钩子
=======================

Nim的标准 ``string`` 和 ``seq`` 类型以及其他标准集合的内存管理是通过所谓的 ``生命周期跟踪钩子`` 或 ``类型绑定运算符`` 执行的。
每个（通用或具体）对象类型有3个不同的钩子 ``T``（ ``T`` 也可以是 ``distinct`` 类型），由编译器隐式调用。

（注意：这里的“钩子”一词并不表示任何类型的动态绑定或运行时间接，隐式调用是静态绑定的，可能是内联的。）
(Note: The word "hook" here does not imply any kind of dynamic binding or runtime indirections, the implicit calls are statically bound and potentially inlined.)


`=destroy` 钩子
---------------

`=destroy` 钩子释放对象的相关内存并释放其他相关资源。当变量超出范围或者声明它们的例程即将返回时，变量会通过此钩子被销毁。

这个类型 ``T`` 的钩子的原型需要是：

.. code-block:: nim

  proc `=destroy`(x: var T)


``=destroy`` 中的一般形式如下：

.. code-block:: nim

  proc `=destroy`(x: var T) =
    # first check if 'x' was moved to somewhere else:
    if x.field != nil:
      freeResource(x.field)
      x.field = nil



`=sink` 钩子
------------

`=sink` 钩子移动一个对象，资源从源头被移动并传递到目的地。 
通过将对象设置为其默认值（对象状态开始的值），确保源的析构函数不会释放资源。
将对象``x``设置回其默认值写为``wasMoved（x）``。

这个类型``T``的钩子的原型需要是：


.. code-block:: nim

  proc `=sink`(dest: var T; source: T)


``=sink`` 的一般形式如下:

.. code-block:: nim

  proc `=sink`(dest: var T; source: T) =
    `=destroy`(dest)
    dest.field = source.field


**注意**: ``=sink`` 不需要检查自赋值。
如何处理自赋值将在本文档后面解释。


`=` (复制) 钩子
---------------

Nim中的普通赋值是概念上地复制值。
对于无法转换为 ``=sink`` 操作的赋值，调用 ``=`` hook。

这个类型 ``T`` 的钩子的原型需要是：

.. code-block:: nim

  proc `=`(dest: var T; source: T)


``=``的一般形式如下：

.. code-block:: nim

  proc `=`(dest: var T; source: T) =
    # 阻止自赋值:
    if dest.field != source.field:
      `=destroy`(dest)
      dest.field = duplicateResource(source.field)


``=`` proc 可以用 ``{.error.}`` 标记。 
然后，在编译时阻止任何可能导致副本的任务。


移动语义
==============

“移动”可以被视为优化的复制操作。
如果之后未使用复制操作的源，则可以通过移动替换副本。
本文档使用符号 ``lastReadOf（x）`` 来描述之后不使用 ``x` `。
此属性由静态流程控制分析计算，但也可以通过显式使用 ``system.move`` 来强制执行。


交换
====

需要检查自赋值以及是否需要销毁 ``=`` 和 ``= sink`` 中的先前对象，这是将 ``system.swap`` 视为内置原语的强大指标。只需通过 ``copyMem`` 或类似机制交换涉及对象中的每个字段。
换句话说， ``swap(a, b)`` is **不是** 实现为 ``let tmp = move(a); b = move(a); a = move(tmp)`` 。

这还有其他后果：

* Nim的模型不支持包含指向同一对象的指针的对象。否则，交换的对象最终会处于不一致状态。
* Seqs可以在实现中使用 ``realloc`` 。


Sink形参
===============

要将变量移动到集合中，通常会涉及 ``sink`` 形参。
之后不应使用传递给 ``sink`` 形参的位置。
这通过控制流图的静态分析来确保。
如果无法证明它是该位置的最后一次使用，则会执行复制，然后将此副本传递给接收器参数。

sink形参 *may* be consumed once in the proc's body but doesn't have to be consumed at all.
The reason for this is that signatures like ``proc put(t: var Table; k: sink Key, v: sink Value)`` should be possible without any further overloads and ``put`` might not take owership of ``k`` if ``k`` already exists in the table. 
Sink parameters enable an affine type system, not a linear type system.

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



重写规则
=============

**注意**: 允许两种不同的实施策略:

1. 生成的 ``finally`` 部分可以是一个环绕整个过程体的单个部分。
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
