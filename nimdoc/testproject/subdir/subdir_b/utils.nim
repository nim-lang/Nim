##[

.. include:: ./utils_overview.rst

# This is now a header

## Next header

### And so on

# More headers

###### Up to level 6


#. An enumeration
#. Second idea here.

More text.

1. Other case value
2. Second case.

Ref group fn2_ or specific function like `fn2()`_
or `fn2(  int  )`_ or `fn2(int,
float)`_.

Ref generics like this: binarySearch_ or `binarySearch(openArray[T], K,
proc (T, K))`_ or `proc binarySearch(openArray[T], K,  proc (T, K))`_ or
in different style: `proc binarysearch(openarray[T], K, proc(T, K))`_.
Can be combined with export symbols and type parameters:
`binarysearch*[T, K](openArray[T], K, proc (T, K))`_.
With spaces `binary search`_.

Note that `proc` can be used in postfix form: `binarySearch proc`_.

Ref. type like G_ and `type G`_ and `G[T]`_ and `type G*[T]`_.

Group ref. with capital letters works: fN11_ or fn11_
]##

include ./utils_helpers

type
  SomeType* = enum
    enumValueA,
    enumValueB,
    enumValueC
  G*[T] = object
    val: T

proc someType*(): SomeType =
  ## constructor.
  SomeType(2)


proc fn2*() = discard ## comment
proc fn2*(x: int) =
  ## fn2 comment
  discard
proc fn2*(x: int, y: float) =
  discard
proc binarySearch*[T, K](a: openArray[T]; key: K;
                         cmp: proc (x: T; y: K): int {.closure.}): int =
  discard
proc fn3*(): auto = 1 ## comment
proc fn4*(): auto = 2 * 3 + 4 ## comment
proc fn5*() ## comment
proc fn5*() = discard
proc fn6*() =
  ## comment
proc fn7*() =
  ## comment
  discard
proc fn8*(): auto =
  ## comment
  1+1
func fn9*(a: int): int = 42  ## comment
func fn10*(a: int): int = a  ## comment

# Note capital letter N will be handled correctly in
# group references like fN11_ or fn11_
# (or [fN11] or [fn11] in Markdown Syntax):

func fN11*() = discard
func fN11*(x: int) = discard

# bug #9235

template aEnum*(): untyped =
  type
    A* {.inject.} = enum ## The enum A.
      aA

template bEnum*(): untyped =
  type
    B* {.inject.} = enum ## The enum B.
      bB

  func someFunc*() =
    ## My someFunc.
    ## Stuff in `quotes` here.
    ## [Some link](https://nim-lang.org)
    discard

template fromUtilsGen*(): untyped =
  ## should be shown in utils.html only
  runnableExamples:
    discard "should be in utils.html only, not in module that calls fromUtilsGen"
  ## ditto

  iterator fromUtils1*(): int =
    runnableExamples:
      # ok1
      assert 1 == 1
      # ok2
    yield 15

  template fromUtils2*() =
    ## ok3
    runnableExamples:
      discard """should be shown as examples for fromUtils2
       in module calling fromUtilsGen"""

  proc fromUtils3*() =
    ## came form utils but should be shown where `fromUtilsGen` is called
    runnableExamples: discard """should be shown as examples for fromUtils3
       in module calling fromUtilsGen"""

proc f*(x: G[int]) =
  ## There is also variant `f(G[string])`_
  discard
proc f*(x: G[string]) =
  ## See also `f(G[int])`_.
  discard

## Ref. `[]`_ is the same as `proc \`[]\`(G[T])`_ because there are no
## overloads. The full form: `proc \`[]\`*[T](x: G[T]): T`_

proc `[]`*[T](x: G[T]): T = x.val

## Ref. `[]=`_ aka `\`[]=\`(G[T], int, T)`_.

proc `[]=`*[T](a: var G[T], index: int, value: T) = discard

## Ref. `$`_ aka `proc $`_ or `proc \`$\``_.

proc `$`*[T](a: G[T]): string = ""

## Ref. `$(a: ref SomeType)`_.

proc `$`*[T](a: ref SomeType): string = ""

## Ref. foo_bar_ aka `iterator foo_bar_`_.

iterator fooBar*(a: seq[SomeType]): int = discard

## Ref. `fn[T; U,V: SomeFloat]()`_.

proc fn*[T; U, V: SomeFloat]() = discard

## Ref. `'big`_ or `func \`'big\``_ or `\`'big\`(string)`_.

func `'big`*(a: string): SomeType = discard

##[

Pandoc Markdown
===============

Now repeat all the auto links of above in Pandoc Markdown Syntax.

Ref group [fn2] or specific function like [fn2()]
or [fn2(  int  )] or [fn2(int,
float)].

Ref generics like this: [binarySearch] or [binarySearch(openArray[T], K,
proc (T, K))] or [proc binarySearch(openArray[T], K,  proc (T, K))] or
in different style: [proc binarysearch(openarray[T], K, proc(T, K))].
Can be combined with export symbols and type parameters:
[binarysearch*[T, K](openArray[T], K, proc (T, K))].
With spaces [binary search].

Note that `proc` can be used in postfix form: [binarySearch proc].

Ref. type like [G] and [type G] and [G[T]] and [type G*[T]].

Group ref. with capital letters works: [fN11] or [fn11]

Ref. [`[]`] is the same as [proc `[]`(G[T])] because there are no
overloads. The full form: [proc `[]`*[T](x: G[T]): T]
Ref. [`[]=`] aka [`[]=`(G[T], int, T)].
Ref. [$] aka [proc $] or [proc `$`].
Ref. [$(a: ref SomeType)].
Ref. [foo_bar] aka [iterator foo_bar_].
Ref. [fn[T; U,V: SomeFloat]()].
Ref. ['big] or [func `'big`] or [`'big`(string)].

Link name syntax
----------------

Pandoc Markdown has synax for changing text of links:
Ref. [this proc][`[]`] or [another symbol][G[T]].

Symbols documentation
---------------------

Let us repeat auto links from symbols section below:

There is also variant [f(G[string])].
See also [f(G[int])].

]##
