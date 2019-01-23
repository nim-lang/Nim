##[
Although this module has ``seq`` in its name, it implements operations
not only for `seq`:idx: type, but for three built-in container types under
the ``openArray`` umbrella:
* sequences
* strings
* array

The system module defines several common functions, such as:
* ``newseq[T]`` for creating new sequences of type ``T``
* ``@`` for converting arrays and strings to sequences
* ``add`` for adding new elements to strings and sequences
* ``&`` for string and seq concatenation
* ``find`` for getting the index of an element
* ``in`` (alias for ``contains``) and ``notin`` for checking if an item is
  in a container

This module builds upon that, providing additional functionality in form of
procs, iterators and templates inspired by functional programming
languages.

For functional style programming you have different options at your disposal:
* pass `anonymous proc<manual.html#procedures-anonymous-procs>`_
* import `sugar module<sugar.html>`_  and use
  `=> macro<sugar.html#%3D>.m,untyped,untyped>`_
* use `...It templates<#18>`_
  (`mapIt<#mapIt.t,typed,untyped>`_,
  `filterIt<#filterIt.t,untyped,untyped>`_, etc.)

The chaining of functions is possible thanks to the
`method call syntax<manual.html#procs-method-call-syntax>`_.
]##

runnableExamples:
  import sugar

  ## Creating a sequence from 1 to 10, multiplying each member by 2,
  ## keeping only the members which are not divisible by 6.
  let
    foo = toSeq(1..10).map(x => x*2).filter(x => x mod 6 != 0)
    bar = toSeq(1..10).mapIt(it*2).filterIt(it mod 6 != 0)

  assert foo == bar
  assert foo == @[2, 4, 8, 10, 14, 16, 20]

  assert foo.any(x => x > 17) == true
  assert bar.allIt(it < 20) == false
  assert foo.foldl(a + b) == 74

runnableExamples:
  from strutils import join

  let
    vowels = @"aeiou" ## creates a sequence @['a', 'e', 'i', 'o', 'u']
    foo = "sequtils is an awesome module"

  assert foo.filterIt(it notin vowels).join == "sqtls s n wsm mdl"

##[
----

**See also**:
* `strutils module<strutils.html>`_ for common string functions
* `sugar module<sugar.html>`_ for syntactic sugar macros
* `algorithm module<algorithm.html>`_ for common generic algorithms
* `json module<json.html>`_ for a structure which allows
  heterogeneous members

]##