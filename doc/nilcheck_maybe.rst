
Not accepted ideas
--------------------

TODO: just for info before finishing 

Those ideas were planned , but probably will not make it, to have a more minimal spec


Old version of not nil refs in sequences
-------------------------

``seq[T]`` where ``T`` is ``ref`` and ``not nil`` are an interesing edge case: they are supported with some limitations.

They can be created with only some overloads of ``newSeq``:  

``newSeq(length, unsafeDefault(T))``: ``default`` isn't defined for ``ref T not nil``, ``unsafeDefault`` is equivalent to ``nil``.
However this should be used only in edge cases.

.. code-block:: nim

  newSeqWithInit(length):
    Object(a: it)

where we pass a block, which fills each value of the result with a valid not nil value in a loop iterating length times where ``it`` is the index

There is special treatment of ``setLen`` related functions as well: one can use ``shrink`` in all cases.
However one can use ``grow`` similarly to ``newSeq`` :

``grow(length, unsafeDefault(T))``: ensuring that you fill the new elements with non nil values manually

.. code-block:: nim

  growWithInit(length):
    Object(a: it)

similar to ``newSeqWithInit``

Many generic algorithms can be done with the the safe ``shrink``, ``newSeqWithInit`` and ``growWithInit``, but ``unsafeDefault`` can be used as an escape hatch.


