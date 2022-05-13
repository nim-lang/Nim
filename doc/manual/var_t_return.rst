.. default-role:: code
.. include:: ../rstcommon.rst

Memory safety for returning by `var T` is ensured by a simple borrowing
rule: If `result` does not refer to a location pointing to the heap
(that is in `result = X` the `X` involves a `ptr` or `ref` access)
then it has to be derived from the routine's first parameter:

.. code-block:: nim
  proc forward[T](x: var T): var T =
    result = x # ok, derived from the first parameter.

  proc p(param: var int): var int =
    var x: int
    # we know 'forward' provides a view into the location derived from
    # its first argument 'x'.
    result = forward(x) # Error: location is derived from `x`
                        # which is not p's first parameter and lives
                        # on the stack.

In other words, the lifetime of what `result` points to is attached to the
lifetime of the first parameter and that is enough knowledge to verify
memory safety at the call site.
