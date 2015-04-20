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
## The ``?`` operator (template) is a shortcut for ``Maybe[T]``.
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
##
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
  Maybe*[T] = object
    ## An optional type that stores its value and state separately in a boolean.
    val: T
    has: bool


template `?`*(T: typedesc): typedesc =
  ## ``?T`` is equivalent to ``Maybe[T]``.
  Maybe[T]


proc just*[T](val: T): Maybe[T] =
  ## Returns a ``Maybe`` that has this value.
  result.has = true
  result.val = val

proc nothing*(T: typedesc): Maybe[T] =
  ## Returns a ``Maybe`` for this type that has no value.
  result.has = false


proc has*(maybe: Maybe): bool =
  ## Returns ``true`` if `maybe` isn't `nothing`.
  maybe.has

converter toBool*(maybe: Maybe): bool =
  ## Same as ``has``. Allows to use a ``Maybe`` in boolean context.
  maybe.has


proc val*[T](maybe: Maybe[T]): T =
  ## Unsafe. Returns the value of a `just`. Behavior is undefined for `nothing`.
  assert maybe.has, "nothing has no val"
  maybe.val

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


proc `==`*(a, b: Maybe): bool =
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


  block: # example
    proc find(haystack: string, needle: char): ?int =
      for i, c in haystack:
        if c == needle:
          return just i

    assert("abc".find('c')[] == 2)

    let result = "team".find('i')

    assert result == nothing(int)
    assert result.has == false

    if pos ?= "nim".find('i'):
      assert pos is int
      assert pos == 1
    else:
      assert false

    assert(("team".find('i') or -1) == -1)
    assert(("nim".find('i') or -1) == 1)

  block: # just
    assert just(6)[] == 6
    assert just("a").val == "a"
    assert just(6).has
    assert just("a")

  block: # nothing
    expect FieldError:
      discard nothing(int)[]
    assert(not nothing(int).has)
    assert(not nothing(string))

  block: # equality
    assert just("a") == just("a")
    assert just(7) != just(6)
    assert just("a") != nothing(string)
    assert nothing(int) == nothing(int)

    when compiles(just("a") == just(5)):
      assert false
    when compiles(nothing(string) == nothing(int)):
      assert false

  block: # stringification
    assert "just(7)" == $just(7)
    assert "nothing(int)" == $nothing(int)

  block: # or
    assert just(1) or just(2) == just(1)
    assert nothing(string) or just("a") == just("a")
    assert nothing(int) or nothing(int) == nothing(int)
    assert just(5) or 2 == 2
    assert nothing(string) or "a" == "a"

    when compiles(just(1) or "2"):
      assert false
    when compiles(nothing(int) or just("a")):
      assert false

  block: # extraction template
    if a ?= just(5):
      assert a == 5
    else:
      assert false

    if b ?= nothing(string):
      assert false
