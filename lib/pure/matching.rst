.. raw:: html
  <blockquote><p>
  "you can probably make a macro for that" -- Rika, 22-09-2020 10:41:51
  </p></blockquote>

:Author: haxscramper

This module implements pattern matching for objects, tuples,
sequences, key-value pairs, case and derived objects. DSL can also be
used to create object trees (AST).



Quick reference
===============

============================= =======================================================
 Example                       Explanation
============================= =======================================================
 ``(fld: @val)``               Field ``fld`` into variable ``@val``
 ``Kind()``                    Object with ``.kind == Kind()`` [1]
 ``of Derived()``              Match object of derived type
 ``(@val, _)``                 First element in tuple in ``@val``
 ``(@val, @val)``              Tuple with two equal elements
 ``{"key" : @val}``            Table with "key", capture into ``@val`` [2]
 ``[_, _]``                    Sequence with ``len == 2`` [3]
 ``[_, .._]``                  At least one element
 ``[_, all @val]``             All elements starting from index ``1``
 ``[until @val == "2", .._]``  Capture all elements *until* first ``"2"`` [4]
 ``[until @val == 1, @val]``   All *including* first match
 ``[all @val == 12]``          All elements are ``== 12``, capture into ``@val``
 ``[some @val == 12]``         At least *one* is ``== 12``, capture all matching into ``@val``
============================= =======================================================

- [1] Kind fields can use shorted enum names - both ``nnkStrLit`` and
  ``StrLit`` will work (prefix ``nnk`` can be omitted)
- [2] Or any object with ``contains`` and ``[]`` defined (for necessary types)
- [3] Or any object with ``len`` proc or field
- [4] Note that sequence must match *fully* and it is necessary to have
  ``.._`` at the end in order to accept sequences of arbitrary length.

Supported match elements
========================

- *seqs* - matched using ``[Patt1(), Patt2(), ..]``. Must have
  ``len(): int`` and ``[int]: T`` defined.
- *tuples* - matched using ``(Patt1(), Patt2(), ..)``.
- *pairable* - matched using ``{Key: Patt()}``. Must have ``[Key]: T``
  defined. ``Key`` is not a pattern - search for whole collection
  won't be performed.
- *set* - matched using ``{Val1, Val2, .._}``. Must have ``contains``
  defined. If variable is captured then ``Val1`` must be comparable
  and collection should also implement ``items`` and ``incl``.
- *object* - matched using ``(field: Val)``. Case objects are matched
  using ``Kind(field: Val)``. If you want to check agains multiple
  values for kind field ``(kind: in SomeSetOfKinds)``

Element access
==============

To determine whether particular object matches pattern *access
path* is generated - sequence of fields and ``[]`` operators that you
would normally write by hand, like ``fld.subfield["value"].len``. Due to
support for `method call syntax
<https://nim-lang.org/docs/manual.html#procedures-method-call-syntax>`_
there is no difference between field access and proc call, so things
like `(len: < 12)` also work as expected.

``(fld: "3")`` Match field ``fld`` against ``"3"``. Generated access
    is ``expr.fld == "3"``.

``["2"]`` Match first element of expression agains patt. Generate
    acess ``expr[pos] == "2"``, where ``pos`` is an integer index for
    current position in sequence.

``("2")`` For each field generate access using ``[1]``

``{"key": "val"}`` First check ``"key" in expr`` and then
    ``expr["key"] == "val"``. No exception on missing keys, just fail
    match.

It is possible to have mixed assess for objects. Mixed object access
via ``(gg: _, [], {})`` creates the same code for checking. E.g ``([_])``
is the same as ``[_]``, ``({"key": "val"})`` is is identical to just
``{"key": "val"}``. You can also call functions and check their values
(like ``(len: _(it < 10))`` or ``(len: in {0 .. 10})``) to check for
sequence length.

Checks
======

- Any operators with exception of ``is`` (subpattern) and ``of`` (derived
  object subpattern) is considered final comparison and just pasted as-is
  into generated pattern match code. E.g. ``fld: in {2,3,4}`` will generate
  ``expr.fld in {2,3,4}``

- ``(fld: Patt())`` - check if ``expr.fld`` matches pattern ``Patt()``

- ``(fld: _.matchesPredicate())`` - if call to
  ``matchesPredicate(expr.fld)`` evaluates to true.

Notation: ``<expr>`` refers to any possible combination of checks. For
example

- ``fld: in {1,2,3}`` - ``<expr>`` is ``in {1,2,3}``
- ``[_]`` - ``<expr>`` is ``_``
- ``fld: Patt()`` - ``<expr>`` is ``Patt()``

Examples
--------

- ``(fld: 12)`` If rhs for key-value pair is integer, string or
  identifier then ``==`` comparison will be generated.
- ``(fld: == ident("33"))`` if rhs is a prefix of ``==`` then ``==`` will
  be generated. Any for of prefix operator will be converted to
  ``expr.fld <op> <rhs>``.
- ``(fld: in {1, 3, 3})`` or ``(fld: in Anything)`` creates ``fld.expr
  in Anything``. Either ``in`` or ``notin`` can be used.

Variable binding
================

Match can be bound to new varaible. All variable declarations happen
via ``@varname`` syntax.

- To bind element to variable without any additional checks do: ``(fld: @varname)``
- To bind element with some additional operator checks do:

  - ``(fld: @varname <operator> Value)`` first perform check using
    ``<operator>`` and then add ``Value`` to ``@varname``
    - ``(fld: @hello is ("2" | "3"))``

- Predicate checks: ``fld: @a.matchPredicate()``
- Arbitrary expression: ``fld: @a(it mod 2 == 0)``. If expression has no
  type it is considered ``true``.

Bind order
----------

Bind order: if check evaluates to true variable is bound immediately,
making it possible to use in other checks. ``[@head, any @tail !=
head]`` is a valid pattern. First match ``head`` and then any number
of ``@tail`` elements. Can use ``any _(if it != head: tail.add it)``
and declare ``tail`` externally.

Variable is never rebound. After it is bound, then it will have the
value of first binding.

Bind variable type
------------------

- Any variadics are mapped to sequence
- Only once in alternative is option
- Explicitly optional is option
- Optional with default value is regular value
- Variable can be used only once if in alternative


========================== =====================================
 Pattern                     Ijected variables
========================== =====================================
 ``[@a]``                    ``var a: typeof(expr[0])``
 ``{"key": @val}``           ``var val: typeof(expr["key"])``
 ``[all @a]``                ``var a: seq[typeof(expr[0])]``
 ``[opt @val]``              ``var a: Option[typeof(expr[0])]``
 ``[opt @val or default]``   ``var a: typeof(expr[0])``
 ``(fld: @val)``             ``var val: typeof(expr.fld)``
========================== =====================================

Matching different things
=========================

Sequence matching
-----------------

Input sequence: ``[1,2,3,4,5,6,5,6]``

================================= ======================== ====================================
 Pattern                           Result                   Comment
================================= ======================== ====================================
 ``[_]``                           **Fail**                 Input sequence size mismatch
 ``[.._]``                         **Ok**
 ``[@a]``                          **Fail**                 Input sequence size mismatch
 ``[@a, .._]``                     **Ok**, ``a = 1``
 ``[any @a, .._]``                 **Error**
 ``[any @a(it < 10)]``             **Ok**, ``a = [1..6]``   Capture all elements that match
 ``[until @a == 6, .._]``          **Ok**                   All until first ocurrence of ``6``
 ``[all @a == 6, .._]``            **Ok** ``a = []``        All leading ``6``
 ``[any @a(it > 100)]``            **Fail**                 No elements ``> 100``
 ``[none @a(it in {6 .. 10})]``    **Fail**                 There is an element ``== 6``
 ``[0 .. 2 is < 10, .._]``         **Ok**                   First three elements ``< 10``
 ``[0 .. 2 is < 10]``              **Fail**                 Missing trailing ``.._``
================================= ======================== ====================================

``until``
    non-greedy. Match everything until ``<expr>``

    - ``until <expr>``: match all until frist element that matches Expr

``all``
    greedy. Match everything that matches ``<expr>``

    - ``all <expr>``: all elements should match Expr

    - ``all @val is <expr>``: capture all elements in ``@val`` if ``<expr>``
      is true for every one of them.
``opt``
    Single element match

    - ``opt @a``: match optional element and bind it to a

    - ``opt @a or "default"``: either match element to a or set a to
      "default"
``any``
    greedy. Consume all sequence elements until the end and
    succed only if any element has matched.

    - ``any @val is "d"``: capture all element that match ``is "d"``

``none``
    greedy. Consume all sequence elements until the end and
    succed only if any element has matched. EE

``[m .. n @capture]``
    Capture slice of elements from index `m` to `n`

Greedy patterns match until the end of a sequence and cannot be
followed by anything else.

For sequence to match is must either be completely matched by all
subpatterns or have trailing ``.._`` in pattern.

============= ============== ==============
 Sequence      Pattern        Match result
============= ============== ==============
 ``[1,2,3]``   ``[1,2]``      **Fail**
               ``[1, .._]``   **Ok**
               ``[1,2,_]``    **Ok**
============= ============== ==============

Use examples
~~~~~~~~~~~~

- capture all elements in sequence: ``[all @elems]``
- get all elements until (not including "d"): ``[until @a is "d"]``
- All leading "d": ``[all @leading is "d"]``
- Match first two elements and ignore the rest ``[_, _, .._]``
- Match optional third element ``[_, _, opt @trail]``
- Match third element and if not matched use default value ``[_, _,
  opt @trail or "default"]``
- Capture all elements until first separator: ``[until @leading is
  "sep", @middle is "sep", all @trailing]``
- Extract all conditions from IfStmt: ``IfStmt([all ElseIf([@cond,
  _]), .._])``


In addition to working with nested subpatterns it is possible to use
pattern matching as simple text scanner, similar to strscans. Main
difference is that it allows to work on arbitrary sequences, meaning it is
possible, for example, to operate on tokens, or as in this example on
strings (for the sake of simplicity).

.. code:: nim

    func allIs(str: string, chars: set[char]): bool = str.allIt(it in chars)

    "2019-10-11 school start".split({'-', ' '}).assertMatch([
      pref @dateParts(it.allIs({'0' .. '9'})),
      pref _(it.allIs({' '})),
      all @text
    ])

    doAssert dateParts == @["2019", "10", "11"]
    doAssert text == @["school", "start"]

Tuple matching
--------------

Input tuple: ``(1, 2, "fa")``

============================ ========== ============
 Pattern                      Result      Comment
============================ ========== ============
 ``(_, _, _)``                **Ok**      Match all
 ``(@a, @a, _)``              **Fail**
 ``(@a is (1 | 2), @a, _)``   **Error**
 ``(1, 1 | 2, _)``            **Ok**
============================ ========== ============

There are not a lot of features implemented for tuple matching, though it
should be noted that `:=` operator can be quite handy when it comes to
unpacking nested tuples -

.. code:: nim

    (@a, (@b, _), _) := ("hello", ("world", 11), 0.2)

Object matching
---------------

For matching object fields you can use ``(fld: value)`` -

.. code:: nim

    type
      Obj = object
        fld1: int8

    func len(o: Obj): int = 0

    case Obj():
      of (fld1: < -10):
        discard

      of (len: > 10):
        # can use results of function evaluation as fields - same idea as
        # method call syntax in regular code.
        discard

      of (fld1: in {1 .. 10}):
        discard

      of (fld1: @capture):
        doAssert capture == 0

Variant object matching
-----------------------

Matching on ``.kind`` field is a very common operation and has special
syntax sugar - ``ForStmt()`` is functionally equivalent to ``(kind:
nnkForStmt)``, but much more concise.

`nnk` pefix can be omitted - in general if your enum field name folows
`nep1` naming `conventions
<https://nim-lang.org/docs/nep1.html#introduction-naming-conventions>`_
(each enum name starts with underscore prefix (common for all enum
elements), followed PascalCase enum name.


Input AST

.. code:: nim

    ForStmt
      Ident "i"
      Infix
        Ident ".."
        IntLit 1
        IntLit 10
      StmtList
        Command
          Ident "echo"
          IntLit 12

- ``ForStmt([== ident("i"), .._])`` Only for loops with ``i`` as
  variable
- ``ForStmt([@a is Ident(), .._])`` Capture for loop variable
- ``ForStmt([@a.isTuple(), .._])`` for loops in which first subnode
  satisfies predicate ``isTuple()``. Bind match to ``a``
- ``ForStmt([_, _, (len: in {1 .. 10})])`` between one to ten
  statements in the for loop body

- Using object name for pattern matching ``ObjectName()`` does not produce
  a hard error, but if ``.kind`` field does not need to be checked ``(fld:
  <pattern>)`` will be sufficient.
- To check ``.kind`` against multiple operators prefix ``in`` can be used -
  ``(kind: in {nnkForStmt, nnkWhileStmt})``


Custom unpackers
----------------

It is possible to unpack regular object using tuple matcher syntax - in
this case overload for ``[]`` operator must be provided that accepts
``static[FieldIndex]`` argument and returns a field.

.. code:: nim

    type
      Point = object
        x: int
        y: int

    proc `[]`(p: Point, idx: static[FieldIndex]): auto =
      when idx == 0:
        p.x
      elif idx == 1:
        p.y
      else:
        static:
          error("Cannot unpack `Point` into three-tuple")

    let point = Point(x: 12, y: 13)

    (@x, @y) := point

    assertEq x, 12
    assertEq y, 13

Note ``auto`` return type for ``[]`` proc - it is necessary if different
types of fields might be returned on tuple unpacking, but not mandatory.

If different fields have varying types ``when`` **must** and ``static`` be
used to allow for compile-time code selection.

Ref object matching
-------------------

It is also possible to match derived ``ref`` objects with patterns using
``of`` operator. It allows for runtime selection of different derived
types.

Note that ``of`` operator is necessary for distinguishing between multiple
derived objects, or getting fields that are present only in derived types.
In addition it performs ``isNil()`` check in the object, so it might be
used in cases when you are not dealing with derived types.

Due to ``isNil()`` check this pattern only makes sense when working with
``ref`` objects.

.. code:: nim

    type
      Base1 = ref object of RootObj
        fld: int

      First1 = ref object of Base1
        first: float

      Second1 = ref object of Base1
        second: string

    let elems: seq[Base1] = @[
      Base1(fld: 123),
      First1(fld: 456, first: 0.123),
      Second1(fld: 678, second: "test"),
      nil
    ]

    for elem in elems:
      case elem:
        of of First1(fld: @capture1, first: @first):
          # Only capture `Frist1` elements
          doAssert capture1 == 456
          doAssert first == 0.123

        of of Second1(fld: @capture2, second: @second):
          # Capture `second` field in derived object
          doAssert capture2 == 678
          doAssert second == "test"

        of of Base1(fld: @default):
          # Match all *non-nil* base elements
          doAssert default == 123

        else:
          doAssert isNil(elem)


..
   Matching for ref objects is not really different from regular one - the
   only difference is that you need to use ``of`` operator explicitly. For
   example, if you want to do ``case`` match for different object kinds - and

   .. code:: nim

       case Obj():
         of of StmtList(subfield: @capture):
           # do something with `capture`

   You can use ``of`` as prefix operator - things like ``{12 : of
   SubRoot(fld1: @fld1)}``, or  ``[any of Derived()]``.


KV-pairs matching
-----------------

Input json string

.. code:: json

    {"menu": {
      "id": "file",
      "value": "File",
      "popup": {
        "menuitem": [
          {"value": "New", "onclick": "CreateNewDoc()"},
          {"value": "Open", "onclick": "OpenDoc()"},
          {"value": "Close", "onclick": "CloseDoc()"}
        ]
      }
    }}

- Get input ``["menu"]["file"]`` from node and

.. code:: nim
    case inj:
      of {"menu" : {"file": @file is JString()}}:
        # ...
      else:
        raiseAssert("Expected [menu][file] as string, but found " & $inj)

Option matching
---------------

``Some(@x)`` and ``None()`` is a special case that will be rewritten into
``(isSome: true, get: @x)`` and ``(isNone: true)`` respectively. This is
made to allow better integration with optional types.  [9]_ .

Tree construction
=================

``makeTree`` provides 'reversed' implementation of pattern matching,
which allows to *construct* tree from pattern, using variables.
Example of use

.. code:: nim

    type
      HtmlNodeKind = enum
        htmlBase = "base"
        htmlHead = "head"
        htmlLink = "link"

      HtmlNode = object
        kind*: HtmlNodeKind
        text*: string
        subn*: seq[HtmlNode]

    func add(n: var HtmlNode, s: HtmlNode) = n.subn.add s

    discard makeTree(HtmlNode):
      base:
        link(text: "hello")

In order to construct tree, ``kind=`` and ``add`` have to be defined.
Internally DSL just creats resulting object, sets ``kind=`` and then
repeatedly ``add`` elements to it. In order to properties for objects
either the field has to be exported, or ``fld=`` has to be defined
(where ``fld`` is the name of property you want to set).

