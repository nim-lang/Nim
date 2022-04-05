===================================
   DrNim User Guide
===================================

:Author: Andreas Rumpf
:Version: |nimversion|

.. default-role:: code
.. include:: rstcommon.rst
.. contents::


Introduction
============

This document describes the usage of the *DrNim* tool. DrNim combines
the Nim frontend with the `Z3 <https://github.com/Z3Prover/z3>`_ proof
engine, in order to allow verify/validate software written in Nim.
DrNim's command-line options are the same as the Nim compiler's.


DrNim currently only checks the sections of your code that are marked
via `staticBoundChecks: on`:

.. code-block:: nim

  {.push staticBoundChecks: on.}
  # <--- code section here ---->
  {.pop.}

DrNim currently only tries to prove array indexing or subrange checks,
overflow errors are *not* prevented. Overflows will be checked for in
the future.

Later versions of the **Nim compiler** will **assume** that the checks inside
the `staticBoundChecks: on` environment have been proven correct and so
it will **omit** the runtime checks. If you do not want this behavior, use
instead `{.push staticBoundChecks: defined(nimDrNim).}`. This way the
Nim compiler remains unaware of the performed proofs but DrNim will prove
your code.


Installation
============

Run `koch drnim`:cmd:, the executable will afterwards be
in ``$nim/bin/drnim``.


Motivating Example
==================

The follow example highlights what DrNim can easily do, even
without additional annotations:

.. code-block:: nim

  {.push staticBoundChecks: on.}

  proc sum(a: openArray[int]): int =
    for i in 0..a.len:
      result += a[i]

  {.pop.}

  echo sum([1, 2, 3])

This program contains a famous "index out of bounds" bug. DrNim
detects it and produces the following error message::

  cannot prove: i <= len(a) + -1; counter example: i -> 0 a.len -> 0 [IndexCheck]

In other words for `i == 0` and `a.len == 0` (for example!) there would be
an index out of bounds error.


Pre-, postconditions and invariants
===================================

DrNim adds 4 additional annotations (pragmas) to Nim:

- `requires`:idx:
- `ensures`:idx:
- `invariant`:idx:
- `assume`:idx:

These pragmas are ignored by the Nim compiler so that they don't have to
be disabled via `when defined(nimDrNim)`.


Invariant
---------

An `invariant` is a proposition that must be true after every loop
iteration, it's tied to the loop body it's part of.


Requires
--------

A `requires` annotation describes what the function expects to be true
before it's called so that it can perform its operation. A `requires`
annotation is also called a `precondition`:idx:.


Ensures
-------

An `ensures` annotation describes what will be true after the function
call. An `ensures` annotation is also called a `postcondition`:idx:.


Assume
------

An `assume` annotation describes what DrNim should **assume** to be true
in this section of the program. It is an unsafe escape mechanism comparable
to Nim's `cast` statement. Use it only when you really know better
than DrNim. You should add a comment to a paper that proves the proposition
you assume.


Example: insertionSort
======================

**Note**: This example does not yet work with DrNim.

.. code-block:: nim

  import std / logic

  proc insertionSort(a: var openArray[int]) {.
      ensures: forall(i in 1..<a.len, a[i-1] <= a[i]).} =

    for k in 1 ..< a.len:
      {.invariant: 1 <= k and k <= a.len.}
      {.invariant: forall(j in 1..<k, i in 0..<j, a[i] <= a[j]).}
      var t = k
      while t > 0 and a[t-1] > a[t]:
        {.invariant: k < a.len.}
        {.invariant: 0 <= t and t <= k.}
        {.invariant: forall(j in 1..k, i in 0..<j, j == t or a[i] <= a[j]).}
        swap a[t], a[t-1]
        dec t

Unfortunately, the invariants required to prove that this code is correct take more
code than the imperative instructions. However, this effort can be compensated
by the fact that the result needs very little testing. Be aware though that
DrNim only proves that after `insertionSort` this condition holds::

  forall(i in 1..<a.len, a[i-1] <= a[i])


This is required, but not sufficient to describe that a `sort` operation
was performed. For example, the same postcondition is true for this proc
which doesn't sort at all:

.. code-block:: nim

  import std / logic

  proc insertionSort(a: var openArray[int]) {.
      ensures: forall(i in 1..<a.len, a[i-1] <= a[i]).} =
    # does not sort, overwrites `a`'s contents!
    for i in 0..<a.len: a[i] = i



Syntax of propositions
======================

The basic syntax is `ensures|requires|invariant: <prop>`.
A `prop` is either a comparison or a compound::

  prop = nim_bool_expression
       | prop 'and' prop
       | prop 'or' prop
       | prop '->' prop # implication
       | prop '<->' prop
       | 'not' prop
       | '(' prop ')' # you can group props via ()
       | forallProp
       | existsProp

  forallProp = 'forall' '(' quantifierList ',' prop ')'
  existsProp = 'exists' '(' quantifierList ',' prop ')'

  quantifierList = quantifier (',' quantifier)*
  quantifier = <new identifier> 'in' nim_iteration_expression


`nim_iteration_expression` here is an ordinary expression of Nim code
that describes an iteration space, for example `1..4` or `1..<a.len`.

`nim_bool_expression` here is an ordinary expression of Nim code of
type `bool` like `a == 3` or `23 > a.len`.

The supported subset of Nim code that can be used in these expressions
is currently underspecified but `let` variables, function parameters
and `result` (which represents the function's final result) are amenable
for verification. The expressions must not have any side-effects and must
terminate.

The operators `forall`, `exists`, `->`, `<->` have to imported
from `std / logic`.
