Strict not nil checking
=========================

.. default-role:: code
.. include:: rstcommon.rst

**Note:** This feature is experimental, you need to enable it with

.. code-block:: nim
  {.experimental: "strictNotNil".}

or 

.. code-block:: cmd
  nim c --experimental:strictNotNil <program>

In the second case it would check builtin and imported modules as well.

It checks the nilability of ref-like types and makes dereferencing safer based on flow typing and `not nil` annotations.

Its implementation is different than the `notnil` one: defined under `strictNotNil`. Keep in mind the difference in option names, be careful with distinguishing them.

We check several kinds of types for nilability:

- ref types
- pointer types
- proc types
- cstrings

nil
-------

The default kind of nilability types is the nilable kind: they can have the value `nil`.
If you have a non-nilable type `T`, you can use `T nil` to get a nilable type for it.


not nil
--------

You can annotate a type where nil isn't a valid value with `not nil`.

.. code-block:: nim
    type
      NilableObject = ref object
        a: int
      Object = NilableObject not nil

      Proc = (proc (x, y: int))
    
    proc p(x: Object) =
      echo x.a # ensured to dereference without an error
    # compiler catches this:
    p(nil)
    # and also this:
    var x: NilableObject
    if x.isNil:
      p(x)
    else:
      p(x) # ok



If a type can include `nil` as a valid value, dereferencing values of the type
is checked by the compiler: if a value which might be nil is derefenced, this
produces a warning by default, you can turn this into an error using
the compiler options `--warningAsError:strictNotNil`:option:.

If a type is nilable, you should dereference its values only after a `isNil` or equivalent check.

local turn on/off
---------------------

You can still turn off nil checking on function/module level by using a `{.strictNotNil: off.}` pragma.
Note: test that/TODO for code/manual.

nilability state
-----------------

Currently a nilable value can be `Safe`, `MaybeNil` or `Nil` : we use internally `Parent` and `Unreachable` but this is an implementation detail(a parent layer has the actual nilability).

- `Safe` means it shouldn't be nil at that point: e.g. after assignment to
  a non-nil value or `not a.isNil` check
- `MaybeNil` means it might be nil, but it might not be nil: e.g. an argument,
  a call argument or a value after an `if` and `else`.
- `Nil` means it should be nil at that point; e.g. after an assignment to
  `nil` or a `.isNil` check.
- `Unreachable` means it shouldn't be possible to access this in this branch:
  so we do generate a warning as well.

We show an error for each dereference (`[]`, `.field`, `[index]` `()` etc) which is of a tracked expression which is
in `MaybeNil` or `Nil` state.


type nilability
----------------

Types are either nilable or non-nilable.
When you pass a param or a default value, we use the type : for nilable types we return `MaybeNil`
and for non-nilable `Safe`.

TODO: fix the manual here. (This is not great, as default values for non-nilables and nilables are usually actually `nil` , so we should think a bit more about this section.)

params rules
------------

Param's nilability is detected based on type nilability. We use the type of the argument to detect the nilability.


assignment rules
-----------------

Let's say we have `left = right`.

When we assign, we pass the right's nilability to the left's expression. There should be special handling of aliasing and compound expressions which we specify in their sections. (Assignment is a possible alias `move` or `move out`).

call args rules
-----------------

When we call with arguments, we have two cases when we might change the nilability.

.. code-block:: nim
  callByVar(a)

Here `callByVar` can re-assign `a`, so this might change `a`'s nilability, so we change it to `MaybeNil`.
This is also a possible aliasing `move out` (moving out of a current alias set).

.. code-block:: nim
  call(a)

Here `call` can change a field or element of `a`, so if we have a dependant expression of `a` : e.g. `a.field`. Dependats become `MaybeNil`.


branches rules
---------------

Branches are the reason we do nil checking like this: with flow checking. 
Sources of brancing are `if`, `while`, `for`, `and`, `or`, `case`, `try` and combinations with `return`, `break`, `continue` and `raise`

We create a new layer/"scope" for each branch where we map expressions to nilability. This happens when we "fork": usually on the beginning of a construct.
When branches "join" we usually unify their expression maps or/and nilabilities.

Merging usually merges maps and alias sets: nilabilities are merged like this:

.. code-block:: nim
  template union(l: Nilability, r: Nilability): Nilability =
    ## unify two states
    if l == r:
      l
    else:
      MaybeNil

Special handling is for `.isNil` and `== nil`, also for `not`, `and` and `or`.

`not` reverses the nilability, `and` is similar to "forking" : the right expression is checked in the layer resulting from the left one and `or` is similar to "merging": the right and left expression should be both checked in the original layer.

`isNil`, `== nil` make expressions `Nil`. If there is a `not` or `!= nil`, they make them `Safe`.
We also reverse the nilability in the opposite branch: e.g. `else`.

compound expressions: field, index expressions
-----------------------------------------------

We want to track also field(dot) and index(bracket) expressions.

We track some of those compound expressions which might be nilable as dependants of their bases: `a.field` is changed if `a` is moved (re-assigned), 
similarly `a[index]` is dependent on `a` and `a.field.field` on `a.field`.

When we move the base, we update dependants to `MaybeNil`. Otherwise we usually start with type nilability.

When we call args, we update the nilability of their dependants to `MaybeNil` as the calls usually can change them.
We might need to check for `strictFuncs` pure funcs and not do that then.

For field expressions `a.field`, we calculate an integer value based on a hash of the tree and just accept equivalent trees as equivalent expressions.

For item expression `a[index]`, we also calculate an integer value based on a hash of the tree and accept equivalent trees as equivalent expressions: for static values only.
For now we support only constant indices: we dont track expression with no-const indices. For those we just report a warning even if they are safe for now: one can use a local variable to workaround. For loops this might be annoying: so one should be able to turn off locally the warning using the `{.warning[StrictCheckNotNil]:off}.`.

For bracket expressions, in the future we might count `a[<any>]` as the same general expression.
This means we should should the index but otherwise handle it the same for assign (maybe "aliasing" all the non-static elements) and differentiate only for static: e.g. `a[0]` and `a[1]`.

element tracking
-----------------

When we assign an object construction, we should track the fields as well: 


.. code-block:: nim
  var a = Nilable(field: Nilable()) # a : Safe, a.field: Safe

Usually we just track the result of an expression: probably this should apply for elements in other cases as well.
Also related to tracking initialization of expressions/fields.

unstructured control flow rules
-------------------------------

Unstructured control flow keywords as `return`, `break`, `continue`, `raise` mean that we jump from a branch out.
This means that if there is code after the finishing of the branch, it would be ran if one hasn't hit the direct parent branch of those: so it is similar to an `else`. In those cases we should use the reverse nilabilities for the local to the condition expressions. E.g.

.. code-block:: nim
  for a in c:
    if not a.isNil:
      b()
      break
    code # here a: Nil , because if not, we would have breaked


aliasing
------------

We support alias detection for local expressions.

We track sets of aliased expressions. We start with all nilable local expressions in separate sets.
Assignments and other changes to nilability can move / move out expressions of sets.

`move`: Moving `left` to `right` means we remove `left` from its current set and unify it with the `right`'s set.
This means it stops being aliased with its previous aliases.

.. code-block:: nim
  var left = b
  left = right # moving left to right

`move out`: Moving out `left` might remove it from the current set and ensure that it's in its own set as a single element.
e.g.


.. code-block:: nim
  var left = b
  left = nil # moving out


initialization of non nilable and nilable values
-------------------------------------------------

TODO

warnings and errors
---------------------

We show an error for each dereference (`[]`, `.field`, `[index]` `()` etc) which is of a tracked expression which is
in `MaybeNil` or `Nil` state.

We might also show a history of the transitions and the reasons for them that might change the nilability of the expression.

