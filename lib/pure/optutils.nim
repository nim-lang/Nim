#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements some more advanced ways to interact with options.
##
## It includes conditional mapping of procedures over an option,
## flattening of nested options, and filtering of values within options.

import options


proc map*[T](self: Option[T], callback: proc (input: T)) =
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
    callback(self.unsafeGet)

proc map*[T, R](self: Option[T], callback: proc (input: T): R): Option[R] =
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
    some[R](callback(self.unsafeGet))
  else:
    none(R)

proc flatten*[A](self: Option[Option[A]]): Option[A] =
  ## Remove one level of structure in a nested `Option`.
  runnableExamples:
    let a = some(some(42))
    assert $flatten(a) == "Some(42)"

  if self.isSome:
    self.unsafeGet
  else:
    none(A)

proc flatMap*[A, B](self: Option[A], callback: proc (input: A): Option[B]): Option[B] =
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

proc filter*[T](self: Option[T], callback: proc (input: T): bool): Option[T] =
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

  if self.isSome and not callback(self.unsafeGet):
    none(T)
  else:
    self

template either*(self, otherwise: untyped): untyped =
  ## Similar in function to `get(self, otherwise) <optionals.html#get,Option[T],T>`_,
  ## but if ``otherwise`` is a procedure it will *not* be evaluated if
  ## ``self`` is a ``some``.
  ##
  ## This means that ``otherwise`` can have side effects.
  let opt = self # In case self is a procedure call returning an option
  if opt.isSome: opt.unsafeGet else: otherwise


when isMainModule:
  import unittest, sequtils

  suite "options":
    # work around a bug in unittest
    let intNone = none(int)
    let stringNone = none(string)

    test "map with a void result":
      var procRan = 0
      some(123).map(proc (v: int) = procRan = v)
      check procRan == 123
      intNone.map(proc (v: int) = check false)

    test "map":
      check(some(123).map(proc (v: int): int = v * 2) == some(246))
      check(intNone.map(proc (v: int): int = v * 2).isNone)

    test "filter":
      check(some(123).filter(proc (v: int): bool = v == 123) == some(123))
      check(some(456).filter(proc (v: int): bool = v == 123).isNone)
      check(intNone.filter(proc (v: int): bool = check false).isNone)

    test "flatMap":
      proc addOneIfNotZero(v: int): Option[int] =
        if v != 0:
          result = some(v + 1)
        else:
          result = none(int)

      check(some(1).flatMap(addOneIfNotZero) == some(2))
      check(some(0).flatMap(addOneIfNotZero) == none(int))
      check(some(1).flatMap(addOneIfNotZero).flatMap(addOneIfNotZero) == some(3))

      proc maybeToString(v: int): Option[string] =
        if v != 0:
          result = some($v)
        else:
          result = none(string)

      check(some(1).flatMap(maybeToString) == some("1"))

      proc maybeExclaim(v: string): Option[string] =
        if v != "":
          result = some v & "!"
        else:
          result = none(string)

      check(some(1).flatMap(maybeToString).flatMap(maybeExclaim) == some("1!"))
      check(some(0).flatMap(maybeToString).flatMap(maybeExclaim) == none(string))

    test "either":
      check(either(some("Correct"), "Wrong") == "Correct")
      check(either(stringNone, "Correct") == "Correct")

    test "either without side effect":
      var evaluated = 0
      proc dummySome(): Option[string] =
        evaluated += 1
        return some("dummy")
      proc dummyStr(): string =
        evaluated += 1
        return "dummy"
      # Check that dummyStr isn't called when we have an option
      check(either(some("Correct"), dummyStr()) == "Correct")
      check evaluated == 0
      # Check that dummyStr is called when we don't have an option
      check(either(stringNone, dummyStr()) == "dummy")
      check evaluated == 1
      evaluated = 0
      # Check that dummySome is only called once when used as the some value
      check(either(dummySome(), "Wrong") == "dummy")
      check evaluated == 1
