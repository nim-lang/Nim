#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## :Author: Oleh Prypin
##
## Abstract
## ========
##
## This module implements types which encapsulate an optional value.
##
## A value of type ``?T`` (``Maybe[T]``) either contains a value `x`
## (represented as ``just(x)``) or is empty (``nothing(T)``).
##
## This can be useful when you have a value that can be present or not.
## The absence of a value is often represented by ``nil``, but it is not always
## available, nor is it always a good solution.
##
##
## Tutorial
## ========
##
## Let's start with an example: a procedure that finds the index of a character
## in a string.
##
## .. code-block:: nim
##
##   import optionals
##
##   proc find(haystack: string, needle: char): ?int =
##     for i, c in haystack:
##       if c == needle:
##         return just i
##     return nothing(int)  # This line is actually optional,
##                          # because the default is empty
##
## The ``?`` operator (template) returns an appropriate ``Maybe`` type for its
## argument. For types that can be `nil` there is an implementation with zero
## memory overhead. The other implementation uses a boolean to store the state.
##
## For typical usage you don't really need to know about these types, just
## use this operator. On the other hand, you don't have to use the operator;
## just specify one of the ``Maybe`` types explicitly.
##
## .. code-block:: nim
##
##   try:
##     assert("abc".find('c')[] == 2)  # Immediately extract the value
##   except FieldError:  # If there is no value
##     assert false  # This will not be reached, because the value is present
##
## The ``[]`` operator demonstrated above returns the underlying value, or
## raises ``FieldError`` if there is no value. There is another option for
## obtaining the value: ``val``, but you must only use it when you are
## absolutely sure the value is present (e.g. after checking ``has``). If you do
## not care about the tiny overhead that ``[]`` causes, you should simply never
## use ``val``.

## How to deal with an absence of a value:
##
## .. code-block:: nim
##
##   let result = "team".find('i')
##
##   # Nothing was found, so the result is `nothing`.
##   assert(result == nothing(int))
##   # It has no value:
##   assert(result.has == false)
##   # A different way to write it:
##   assert(not result)
##
##   try:
##     echo result[]
##     assert(false)  # This will not be reached
##   except FieldError:  # Because an exception is raised
##     discard
##
## Now let's try out the extraction template. It returns whether a value
## is present and injects the value into a variable. It is meant to be used in
## a conditional.
##
## .. code-block:: nim
##
##   if pos ?= "nim".find('i'):
##     assert(pos is int)  # This is a normal integer, no tricks.
##     echo "Match found at position ", pos
##   else:
##     assert(false)  # This will not be reached
##
## Or maybe you want to get the behavior of the standard library's ``find``,
## which returns `-1` if nothing was found.
##
## .. code-block:: nim
##
##   assert(("team".find('i') or -1) == -1)
##   assert(("nim".find('i') or -1) == 1)

import typetraits


type
  Nullable = concept x
    isNil(x) is bool

  Just*[T] = distinct T
    ## A ``Maybe`` type that can only be `just`; it always has a value.
  Nothing*[T] = distinct T
    ## A ``Maybe`` type that can only be `nothing`; it never has a value.

  MaybeObj*[T] = object
    ## A ``Maybe`` type that stores its value and state separately in a boolean.
    ##
    ## It works for all types of values.
    val: T
    has: bool

  MaybeDistinct*[T] = distinct T
    ## A ``Maybe`` type that is `nothing` when the underlying object ``isNil``.
    ##
    ## ``MaybeDistinct`` relies on the value being `nil` or non-`nil` (so actual
    ## `nil` values can't be stored in it). This doesn't necessarily mean
    ## equality or inequality to ``nil``. This ``Maybe`` type is chosen by
    ## ``?T`` for all types that have ``isNil`` defined. It also has the
    ## requirement that the default state of the type without any initialization
    ## (i.e. all zeros) is the ``isNil`` state. If this is not the case, you
    ## need to also define a ``getNil`` proc that returns the `nil` state, like
    ## in the example:
    ##
    ## .. code-block:: nim
    ##
    ##   proc getNil(T: typedesc[Slice[int]]): Slice[int] =
    ##     int.low..int.low
    ##   proc isNil(s: Slice[int]): bool =
    ##     s.a == int.low and s.b == int.low
    ##
    ##   assert(?Slice[int] is MaybeDistinct) # Would've been `MaybeObj`
    ##                                        # without previous procs
    ##   assert(?nothing(int.low..int.low).has == false)

  # Maybe*[T] = concept x
  #   val(x) is T
  #   has(x) is bool
  Maybe*[T] = Just[T] or Nothing[T] or MaybeObj[T] or MaybeDistinct[T]


template `?`*(T: typedesc): typedesc =
  ## Returns ``MaybeDistinct[T]`` for types that have ``isNil`` defined
  ## and ``MaybeObj[T]`` for others. This can be overridden.
  ##
  ## .. code-block:: nim
  ##
  ##   assert(?string is MaybeDistinct)
  ##   assert(?int is MaybeObj)
  ##
  ##   template `?`*(T: typedesc[MyType]): typedesc = MaybeObj[T]
  when T is Nullable:
    MaybeDistinct[T]
  else:
    MaybeObj[T]


proc has*[T](maybe: MaybeObj[T]): bool =
  ## Returns ``true`` if `maybe` isn't `nothing`.
  maybe.has

proc has*[T](maybe: MaybeDistinct[T]): bool =
  ## Returns ``true`` if `maybe` isn't `nothing`.
  mixin isNil
  not isNil(T(maybe))


converter toBool*(maybe: Maybe): bool =
  ## Same as ``has``. Allows to use a ``Maybe`` in boolean context.
  maybe.has


proc val*[T](maybe: MaybeObj[T]): T =
  ## Unsafe. Returns the value of a `just`. Behavior is undefined for `nothing`.
  assert just.has, "nothing has no val"
  maybe.val

proc val*[T](maybe: MaybeDistinct[T]): T =
  ## Unsafe. Returns the value of a `just`. Behavior is undefined for `nothing`.
  assert maybe.has, "nothing has no val"
  T(maybe)


proc `[]`*[T](maybe: Maybe[T]): T =
  ## Returns the value of `maybe`. Raises ``FieldError`` if it is `nothing`.
  if not maybe:
    raise newException(FieldError, "Can't obtain a value from a `nothing`")
  maybe.val

template `or`*[T](maybe: Maybe[T], default: T): T =
  ## Returns the value of `maybe`, or `default` if it is `nothing`.
  if maybe: maybe.val
  else: default

template `or`*[T](a, b: Maybe[T]): Maybe[T] =
  ## Returns `a` if it is `just`, otherwise `b`.
  if a: a
  else: b

template `?=`*(into: expr, maybe: Maybe): bool =
  ## Returns ``true`` if `maybe` isn't `nothing`.
  ##
  ## Injects a variable with the name specified by the argument `into`
  ## with the value of `maybe`, or its type's default value if it is `nothing`.
  ##
  ## .. code-block:: nim
  ##
  ##   proc message(): ?string =
  ##     just "Hello"
  ##
  ##   if m ?= message():
  ##     echo m
  var into {.inject.}: type(maybe.val)
  if maybe:
    into = maybe.val
  maybe


proc just*[T](val: T): Just[T] =
  ## Returns a ``Just`` from this value. It can be converted to more useful
  ## ``Maybe`` types automatically, or ``?just(val)`` may be used to convert it
  ## to ``?T``.
  ##
  ## .. code-block:: nim
  ##
  ##   assert(type(?just 5) is ?int)
  ##   assert((just 5).has)
  Just[T](val)

proc has*(just: Just): bool =
  ## Returns ``true``.
  true

proc val*[T](just: Just[T]): T =
  ## Returns the underlying value. ``val`` is safe only for ``Just``,
  ## because a ``Just`` can't not have a value.
  T(just)

converter toMaybeObj*[T](just: Just[T]): MaybeObj[T] =
  MaybeObj[T](has: true, val: T(just))

converter toMaybeDistinct*[T](just: Just[T]): MaybeDistinct[T] =
  mixin isNil
  if isNil(T(just)):
    raise newException(ValueError, "Can't create a `just` from nil")
  MaybeDistinct[T](T(just))


proc nothing*(T: typedesc): Nothing[T] =
  ## Returns a ``Nothing`` for this type. It can be converted to more useful
  ## ``Maybe`` types automatically, or ``?nothing(T)`` may be used to convert it
  ## to ``?T``.
  ##
  ## .. code-block:: nim
  ##
  ##   assert(type(?nothing(string)) is ?string)
  ##   assert(nothing(string).has == false)
  mixin getNil
  var res: T
  when compiles(getNil(T)):
    res = getNil(T)
  Nothing[T](res)

proc has*[T](nothing: Nothing[T]): bool =
  ## Returns ``false``.
  false

proc val*[T](nothing: Nothing[T]): T =
  ## Unsafe. Undefined behavior.
  assert false, "nothing has no val"

converter toMaybeObj*[T](nothing: Nothing[T]): MaybeObj[T] =
  MaybeObj[T]()

converter toMaybeDistinct*[T](nothing: Nothing[T]): MaybeDistinct[T] =
  if not isNil(T(nothing)):
    raise newException(ValueError, "Can't create a `nothing` from non-nil")
  MaybeDistinct[T](T(nothing))


proc `?`*[T](m: Just[T] or Nothing[T]): auto =
  ## This is not needed for typical usage. See also: ``?`` template.
  ##
  ## Converts a ``Just`` or ``Nothing`` (which are limited 0-overhead types that
  ## cannot change state) into a ``MaybeObj`` or ``MaybeDistinct`` (decided by
  ## the ``?T`` template), by applying one of the converters.
  mixin `?`
  let res: ?T = m
  res


# See issue #1385
proc `==`*(a: Just or Nothing or MaybeObj or MaybeDistinct,
           b: Just or Nothing or MaybeObj or MaybeDistinct): bool =
  ## Returns ``true`` if both ``Maybe`` are `nothing`,
  ## or if they have equal values
  (a.has and b.has and a.val == b.val) or (not a.has and not b.has)

proc `$`[T](maybe: Maybe[T]): string =
  ## Converts to string: `"just(value)"` or `"nothing(type)"`
  if maybe.has:
    "just(" & $maybe.val & ")"
  else:
    "nothing(" & T.name & ")"


when isMainModule:
  template expect(E: expr, body: stmt) =
    try:
      body
      assert false, E.type.name & " not raised"
    except E:
      discard


  block:
    proc find(haystack: string, needle: char): ?int =
      for i, c in haystack:
        if c == needle:
          return just i

    assert("abc".find('c')[] == 2)
    assert("abc".find('c') == just 2)


    let result = "team".find('i')

    assert result == nothing(int)
    assert result.has == false

    expect FieldError:
      discard result[]


    if pos ?= "nim".find('i'):
      assert pos is int
      assert pos == 1
    else:
      assert false

    if pos ?= nothing(int):
      assert false


    assert(("team".find('i') or -1) == -1)
    assert(("nim".find('i') or -1) == 1)


  block:
    assert(?string is MaybeDistinct)
    assert(?int is MaybeObj)

    assert(type(?just 5) is ?int)
    assert((?just 5).has)


    assert(type(?nothing(string)) is ?string)
    assert((?nothing(string)).has == false)


    assert(?nothing(string) == ?nothing(string))
    assert(?just("abc") == ?just("abc"))

    assert(?nothing(int) == ?nothing(int))
    assert(?just(7) == ?just(7))

    var nilstr: string
    expect ValueError:
      discard ?just(nilstr)


  block:
    proc getNil(T: typedesc[Slice[int]]): Slice[int] =
      int.low..int.low
    proc isNil(s: Slice[int]): bool =
      s.a == int.low and s.b == int.low

    assert(?Slice[int] is MaybeDistinct)
    assert type(?nothing(Slice[int])) is MaybeDistinct
    assert((?nothing(Slice[int])).has == false)
    assert((?just(1..int.low)).has)

    expect ValueError:
      discard ?just(int.low..int.low)


  block:
    template `?`*(T: typedesc[seq[int]]): typedesc = MaybeObj[T]

    assert type(?just(@[5])) is MaybeObj


  block:
    var a = toMaybeObj(just "abc")
    var b = toMaybeDistinct(just "abc")
    assert(a == b)
