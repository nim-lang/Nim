#
#
#            Nim's Runtime Library
#        (c) Copyright 2022 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

##[
This module implements a type which encapsulate an optional value.

A value of type `Optional[T]` either contains a value `x` (represented as
`some(x)`) or is empty (`none(T)`).

This can be useful when you have a value that can be present or not. The
absence of a value is often represented by `nil`, but that is not always
available, nor is it always a good solution.


Basic usage
===========

Let's start with an example: a procedure that finds the index of a character
in a string.
]##

runnableExamples:
  proc find(haystack: string, needle: char): Optional[int] =
    for i, c in haystack:
      if c == needle:
        return some(i)
    return none(int)  # This line is actually optional,
                      # because the default is empty

  let found = "abc".find('c')
  assert found.isSome and found.get() == 2

##[
The `get` operation demonstrated above returns the underlying value, or
raises `UnpackDefect` if there is no value. Note that `UnpackDefect`
inherits from `system.Defect` and should therefore never be caught.
Instead, rely on checking if the optional contains a value with the
`isSome <#isSome,Optional[T]>`_ and `isNone <#isNone,Optional[T]>`_ procs.
]##


import typetraits

when defined(nimPreviewSlimSystem):
  import std/assertions


type
  SomePointer = ref | ptr | pointer | proc # xxx what about cstring? proc vs closure?
  Optional*[T] = object
    ## An optional type that may or may not contain a value of type `T`.
    val: T
    has: bool

  UnpackDefect* = object of Defect

template maybeOptional*[T](_: typedesc[T]): untyped =
  ## Return `T` if T is `ref | ptr | pointer | proc`, else `Optional[T]`
  runnableExamples:
    assert maybeOptional(ref int) is ref int
    assert maybeOptional(int) is Optional[int]
  when T is SomePointer: T
  else: Optional[T]

proc optional*[T](val: sink T): Optional[T] {.inline.} =
  ## Can be used to convert a pointer type (`ptr`, `pointer`, `ref` or `proc`) to an optional type.
  ## It converts `nil` to `none(T)`. When `T` is no pointer type, this is equivalent to `some(val)`.
  ##
  ## **See also:**
  ## * `some proc <#some,T>`_
  ## * `none proc <#none,typedesc>`_
  runnableExamples:
    type
      Foo = ref object
    assert optional[Foo](nil).isNone
    assert optional(Foo(nil)).isNone
    assert some(Foo(nil)).isSome
    assert optional(42).isSome
  when T is SomePointer:
    result.val = val
    result.has = val != nil
  else:
    result.val = val
    result.has = true

proc some*[T](val: sink T): Optional[T] {.inline.} =
  ## Returns an `Optional` that has the value `val`.
  ##
  ## **See also:**
  ## * `optional proc <#optional,T>`_
  ## * `none proc <#none,typedesc>`_
  ## * `isSome proc <#isSome,Optional[T]>`_
  runnableExamples:
    let a = some("abc")
    assert a.isSome
    assert a.get == "abc"

    let b: ref int = nil
    assert some(b).isSome
    assert optional(b).isNone

  result.has = true
  result.val = val

proc none*(T: typedesc): Optional[T] {.inline.} =
  ## Returns an `Optional` for this type that has no value.
  ##
  ## **See also:**
  ## * `optional proc <#optional,T>`_
  ## * `some proc <#some,T>`_
  ## * `isNone proc <#isNone,Optional[T]>`_
  runnableExamples:
    assert none(int).isNone

  # the default is the none type
  discard

proc none*[T](): Optional[T] {.inline.} =
  ## Alias for `none(T) <#none,typedesc>`_.
  none(T)

proc isSome*[T](self: Optional[T]): bool {.inline.} =
  ## Checks if an `Optional` contains a value.
  ##
  ## **See also:**
  ## * `isNone proc <#isNone,Optional[T]>`_
  ## * `some proc <#some,T>`_
  runnableExamples:
    assert some(42).isSome
    assert not none(string).isSome
  self.has

proc isNone*[T](self: Optional[T]): bool {.inline.} =
  ## Checks if an `Optional` is empty.
  ##
  ## **See also:**
  ## * `isSome proc <#isSome,Optional[T]>`_
  ## * `none proc <#none,typedesc>`_
  runnableExamples:
    assert not some(42).isNone
    assert none(string).isNone
  not self.has

proc get*[T](self: Optional[T]): lent T {.inline.} =
  ## Returns the content of an `Optional`. If it has no value,
  ## an `UnpackDefect` exception is raised.
  ##
  ## **See also:**
  ## * `get proc <#get,Optional[T],T>`_ with a default return value
  runnableExamples:
    assert some(42).get == 42
    doAssertRaises(UnpackDefect):
      echo none(string).get

  if self.isNone:
    raise newException(UnpackDefect, "Can't obtain a value from a `none`")
  result = self.val

proc get*[T](self: Optional[T], otherwise: T): T {.inline.} =
  ## Returns the content of the `Optional` or `otherwise` if
  ## the `Optional` has no value.
  runnableExamples:
    assert some(42).get(9999) == 42
    assert none(int).get(9999) == 9999

  if self.isSome:
    self.val
  else:
    otherwise

proc get*[T](self: var Optional[T]): var T {.inline.} =
  ## Returns the content of the `var Optional` mutably. If it has no value,
  ## an `UnpackDefect` exception is raised.
  runnableExamples:
    var
      a = some(42)
      b = none(string)
    inc(a.get)
    assert a.get == 43
    doAssertRaises(UnpackDefect):
      echo b.get

  if self.isNone:
    raise newException(UnpackDefect, "Can't obtain a value from a `none`")
  return self.val

proc map*[T](self: Optional[T], callback: proc (input: T)) {.inline.} =
  ## Applies a `callback` function to the value of the `Optional`, if it has one.
  ##
  ## **See also:**
  ## * `map proc <#map,Optional[T],proc(T)_2>`_ for a version with a callback
  ##   which returns a value
  runnableExamples:
    var d = 0
    proc saveDouble(x: int) =
      d = 2 * x

    none(int).map(saveDouble)
    assert d == 0
    some(42).map(saveDouble)
    assert d == 84

  if self.isSome:
    callback(self.val)

proc map*[T, R](self: Optional[T], callback: proc (input: T): R): Optional[R] {.inline.} =
  ## Applies a `callback` function to the value of the `Optional` and returns an
  ## `Optional` containing the new value.
  ##
  ## If the `Optional` has no value, `none(R)` will be returned.
  ##
  ## **See also:**
  ## * `map proc <#map,Optional[T],proc(T)>`_
  ## * `flatMap proc <#flatMap,Optional[T],proc(T)>`_ for a version with a
  ##   callback that returns an `Optional`
  runnableExamples:
    proc isEven(x: int): bool =
      x mod 2 == 0

    assert some(42).map(isEven) == some(true)
    assert none(int).map(isEven) == none(bool)

  if self.isSome:
    some[R](callback(self.val))
  else:
    none(R)

proc flatten*[T](self: Optional[Optional[T]]): Optional[T] {.inline.} =
  ## Remove one level of structure in a nested `Optional`.
  ##
  ## **See also:**
  ## * `flatMap proc <#flatMap,Optional[T],proc(T)>`_
  runnableExamples:
    assert flatten(some(some(42))) == some(42)
    assert flatten(none(Optional[int])) == none(int)

  if self.isSome:
    self.val
  else:
    none(T)

proc flatMap*[T, R](self: Optional[T],
                    callback: proc (input: T): Optional[R]): Optional[R] {.inline.} =
  ## Applies a `callback` function to the value of the `Optional` and returns the new value.
  ##
  ## If the `Optional` has no value, `none(R)` will be returned.
  ##
  ## This is similar to `map`, with the difference that the `callback` returns an
  ## `Optional`, not a raw value. This allows multiple procs with a
  ## signature of `A -> Optional[B]` to be chained together.
  ##
  ## See also:
  ## * `flatten proc <#flatten,Optional[Optional[A]]>`_
  ## * `filter proc <#filter,Optional[T],proc(T)>`_
  runnableExamples:
    proc doublePositives(x: int): Optional[int] =
      if x > 0:
        some(2 * x)
      else:
        none(int)

    assert some(42).flatMap(doublePositives) == some(84)
    assert none(int).flatMap(doublePositives) == none(int)
    assert some(-11).flatMap(doublePositives) == none(int)

  map(self, callback).flatten()

proc filter*[T](self: Optional[T], callback: proc (input: T): bool): Optional[T] {.inline.} =
  ## Applies a `callback` to the value of the `Optional`.
  ##
  ## If the `callback` returns `true`, the optional is returned as `some`.
  ## If it returns `false`, it is returned as `none`.
  ##
  ## **See also:**
  ## * `flatMap proc <#flatMap,Optional[A],proc(A)>`_
  runnableExamples:
    proc isEven(x: int): bool =
      x mod 2 == 0

    assert some(42).filter(isEven) == some(42)
    assert none(int).filter(isEven) == none(int)
    assert some(-11).filter(isEven) == none(int)

  if self.isSome and not callback(self.val):
    none(T)
  else:
    self

proc `==`*[T](a, b: Optional[T]): bool {.inline.} =
  ## Returns `true` if both `Optional`s are `none`,
  ## or if they are both `some` and have equal values.
  runnableExamples:
    let
      a = some(42)
      b = none(int)
      c = some(42)
      d = none(int)

    assert a == c
    assert b == d
    assert not (a == b)

  (a.isSome and b.isSome and a.val == b.val) or (a.isNone and b.isNone)

proc `$`*[T](self: Optional[T]): string =
  ## Get the string representation of the `Optional`.
  runnableExamples:
    assert $some(42) == "some(42)"
    assert $none(int) == "none(int)"

  if self.isSome:
    result = "some("
    result.addQuoted self.val
    result.add ")"
  else:
    result = "none(" & name(T) & ")"

proc unsafeGet*[T](self: Optional[T]): lent T {.inline.}=
  ## Returns the value of a `some`. The behavior is undefined for `none`.
  ##
  ## **Note:** Use this only when you are **absolutely sure** the value is present
  ## (e.g. after checking with `isSome <#isSome,Optional[T]>`_).
  ## Generally, using the `get proc <#get,Optional[T]>`_ is preferred.
  assert self.isSome
  result = self.val
