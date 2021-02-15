#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements types which encapsulate an optional value.
##
## A value of type `Option[T]` either contains a value `x` (represented as
## `some(x)`) or is empty (`none(T)`).
##
## This can be useful when you have a value that can be present or not. The
## absence of a value is often represented by `nil`, but it is not always
## available, nor is it always a good solution.
##
##
## Basic usage
## ===========
##
## Let's start with an example: a procedure that finds the index of a character
## in a string.
##
runnableExamples:
  proc find(haystack: string, needle: char): Option[int] =
    for i, c in haystack:
      if c == needle:
        return some(i)
    return none(int)  # This line is actually optional,
                      # because the default is empty

  let found = "abc".find('c')
  assert found.isSome and found.get() == 2

## The `get` operation demonstrated above returns the underlying value, or
## raises `UnpackDefect` if there is no value. Note that `UnpackDefect`
## inherits from `system.Defect`, and should therefore never be caught.
## Instead, rely on checking if the option contains a value with
## `isSome <#isSome,Option[T]>`_ and `isNone <#isNone,Option[T]>`_ procs.
## 
## How to deal with an absence of a value:

runnableExamples:
  let result = none(int)
  # It has no value:
  assert(result.isNone)

import typetraits

when (NimMajor, NimMinor) >= (1, 1):
  type
    SomePointer = ref | ptr | pointer | proc
else:
  type
    SomePointer = ref | ptr | pointer

type
  Option*[T] = object
    ## An optional type that stores its value and state separately in a boolean.
    when T is SomePointer:
      val: T
    else:
      val: T
      has: bool

  UnpackDefect* = object of Defect
  UnpackError* {.deprecated: "See corresponding Defect".} = UnpackDefect

proc option*[T](val: T): Option[T] {.inline.} =
  ## Can be used to convert a pointer type (`ptr` or `ref` or `proc`) to an option type.
  ## It converts `nil` to `None`.
  ##
  ## See also:
  ## * `some <#some,T>`_
  ## * `none <#none,typedesc>`_
  runnableExamples:
    type
      Foo = ref object
        a: int
        b: string
    var c: Foo
    assert c.isNil
    var d = option(c)
    assert d.isNone

  result.val = val
  when T isnot SomePointer:
    result.has = true

proc some*[T](val: T): Option[T] {.inline.} =
  ## Returns an `Option` that has the value `val`.
  ##
  ## See also:
  ## * `option <#option,T>`_
  ## * `none <#none,typedesc>`_
  ## * `isSome <#isSome,Option[T]>`_
  runnableExamples:
    var
      a = some("abc")
      b = some(42)
    assert $typeof(a) == "Option[system.string]"
    assert b.isSome
    assert a.get == "abc"
    assert $b == "Some(42)"

  when T is SomePointer:
    assert(not val.isNil)
    result.val = val
  else:
    result.has = true
    result.val = val

proc none*(T: typedesc): Option[T] {.inline.} =
  ## Returns an `Option` for this type that has no value.
  ##
  ## See also:
  ## * `option <#option,T>`_
  ## * `some <#some,T>`_
  ## * `isNone <#isNone,Option[T]>`_
  runnableExamples:
    var a = none(int)
    assert a.isNone
    assert $typeof(a) == "Option[system.int]"

  # the default is the none type
  discard

proc none*[T]: Option[T] {.inline.} =
  ## Alias for `none(T) proc <#none,typedesc>`_.
  none(T)

proc isSome*[T](self: Option[T]): bool {.inline.} =
  ## Checks if an `Option` contains a value.
  runnableExamples:
    var
      a = some(42)
      b = none(string)
    assert a.isSome
    assert not b.isSome

  when T is SomePointer:
    not self.val.isNil
  else:
    self.has

proc isNone*[T](self: Option[T]): bool {.inline.} =
  ## Checks if an `Option` is empty.
  runnableExamples:
    var
      a = some(42)
      b = none(string)
    assert not a.isNone
    assert b.isNone
  when T is SomePointer:
    self.val.isNil
  else:
    not self.has

proc get*[T](self: Option[T]): lent T {.inline.} =
  ## Returns contents of an `Option`. If it is `None`, then an exception is
  ## thrown.
  ##
  ## See also:
  ## * `get proc <#get,Option[T],T>`_ with the default return value
  runnableExamples:
    let
      a = some(42)
      b = none(string)
    assert a.get == 42
    doAssertRaises(UnpackDefect):
      echo b.get

  if self.isNone:
    raise newException(UnpackDefect, "Can't obtain a value from a `none`")
  result = self.val

proc get*[T](self: Option[T], otherwise: T): T {.inline.} =
  ## Returns the contents of the `Option` or an `otherwise` value if
  ## the `Option` is `None`.
  runnableExamples:
    var
      a = some(42)
      b = none(int)
    assert a.get(9999) == 42
    assert b.get(9999) == 9999

  if self.isSome:
    self.val
  else:
    otherwise

proc get*[T](self: var Option[T]): var T {.inline.} =
  ## Returns contents of the `var Option`. If it is `None`, then an exception
  ## is thrown.
  runnableExamples:
    let
      a = some(42)
      b = none(string)
    assert a.get == 42
    doAssertRaises(UnpackDefect):
      echo b.get

  if self.isNone:
    raise newException(UnpackDefect, "Can't obtain a value from a `none`")
  return self.val

proc map*[T](self: Option[T], callback: proc (input: T)) {.inline.} =
  ## Applies a `callback` function to the value of the `Option`, if it has one.
  ##
  ## See also:
  ## * `map proc <#map,Option[T],proc(T)_2>`_ for a version with a callback
  ##   which returns a value
  ## * `filter proc <#filter,Option[T],proc(T)>`_
  runnableExamples:
    var d = 0
    proc saveDouble(x: int) =
      d = 2*x

    let
      a = some(42)
      b = none(int)

    b.map(saveDouble)
    assert d == 0
    a.map(saveDouble)
    assert d == 84

  if self.isSome:
    callback(self.val)

proc map*[T, R](self: Option[T], callback: proc (input: T): R): Option[R] {.inline.} =
  ## Applies a `callback` function to the value of the `Option` and returns an
  ## `Option` containing the new value.
  ##
  ## If the `Option` is `None`, `None` of the return type of the `callback`
  ## will be returned.
  ##
  ## See also:
  ## * `flatMap proc <#flatMap,Option[A],proc(A)>`_ for a version with a
  ##   callback which returns an `Option`
  ## * `filter proc <#filter,Option[T],proc(T)>`_
  runnableExamples:
    var
      a = some(42)
      b = none(int)

    proc isEven(x: int): bool =
      x mod 2 == 0

    assert $(a.map(isEven)) == "Some(true)"
    assert $(b.map(isEven)) == "None[bool]"

  if self.isSome:
    some[R](callback(self.val))
  else:
    none(R)

proc flatten*[A](self: Option[Option[A]]): Option[A] {.inline.} =
  ## Remove one level of structure in a nested `Option`.
  runnableExamples:
    let a = some(some(42))
    assert $flatten(a) == "Some(42)"

  if self.isSome:
    self.val
  else:
    none(A)

proc flatMap*[A, B](self: Option[A],
                    callback: proc (input: A): Option[B]): Option[B] {.inline.} =
  ## Applies a `callback` function to the value of the `Option` and returns an
  ## `Option` containing the new value.
  ##
  ## If the `Option` is `None`, `None` of the return type of the `callback`
  ## will be returned.
  ##
  ## Similar to `map`, with the difference that the `callback` returns an
  ## `Option`, not a raw value. This allows multiple procs with a
  ## signature of `A -> Option[B]` to be chained together.
  ##
  ## See also:
  ## * `flatten proc <#flatten,Option[Option[A]]>`_
  ## * `filter proc <#filter,Option[T],proc(T)>`_
  runnableExamples:
    proc doublePositives(x: int): Option[int] =
      if x > 0:
        return some(2*x)
      else:
        return none(int)
    let
      a = some(42)
      b = none(int)
      c = some(-11)
    assert a.flatMap(doublePositives) == some(84)
    assert b.flatMap(doublePositives) == none(int)
    assert c.flatMap(doublePositives) == none(int)

  map(self, callback).flatten()

proc filter*[T](self: Option[T], callback: proc (input: T): bool): Option[T] {.inline.} =
  ## Applies a `callback` to the value of the `Option`.
  ##
  ## If the `callback` returns `true`, the option is returned as `Some`.
  ## If it returns `false`, it is returned as `None`.
  ##
  ## See also:
  ## * `map proc <#map,Option[T],proc(T)_2>`_
  ## * `flatMap proc <#flatMap,Option[A],proc(A)>`_
  runnableExamples:
    proc isEven(x: int): bool =
      x mod 2 == 0
    let
      a = some(42)
      b = none(int)
      c = some(-11)
    assert a.filter(isEven) == some(42)
    assert b.filter(isEven) == none(int)
    assert c.filter(isEven) == none(int)

  if self.isSome and not callback(self.val):
    none(T)
  else:
    self

proc `==`*(a, b: Option): bool {.inline.} =
  ## Returns `true` if both `Option`s are `None`,
  ## or if they are both `Some` and have equal values.
  runnableExamples:
    let
      a = some(42)
      b = none(int)
      c = some(42)
      d = none(int)

    assert a == c
    assert b == d
    assert not (a == b)

  (a.isSome and b.isSome and a.val == b.val) or (not a.isSome and not b.isSome)

proc `$`*[T](self: Option[T]): string =
  ## Get the string representation of the `Option`.
  ##
  ## If the `Option` has a value, the result will be `Some(x)` where `x`
  ## is the string representation of the contained value.
  ## If the `Option` does not have a value, the result will be `None[T]`
  ## where `T` is the name of the type contained in the `Option`.
  if self.isSome:
    result = "Some("
    result.addQuoted self.val
    result.add ")"
  else:
    result = "None[" & name(T) & "]"

proc unsafeGet*[T](self: Option[T]): lent T {.inline.}=
  ## Returns the value of a `some`. Behavior is undefined for `none`.
  ##
  ## **Note:** Use it only when you are **absolutely sure** the value is present
  ## (e.g. after checking `isSome <#isSome,Option[T]>`_).
  ## Generally, using `get proc <#get,Option[T]>`_ is preferred.
  assert self.isSome
  result = self.val
