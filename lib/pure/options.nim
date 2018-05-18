#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Abstract
## ========
##
## This module implements types which encapsulate an optional value.
##
## A value of type ``Option[T]`` either contains a value `x` (represented as
## ``some(x)``) or is empty (``none(T)``).
##
## This can be useful when you have a value that can be present or not. The
## absence of a value is often represented by ``nil``, but it is not always
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
##   import options
##
##   proc find(haystack: string, needle: char): Option[int] =
##     for i, c in haystack:
##       if c == needle:
##         return some(i)
##     return none(int)  # This line is actually optional,
##                       # because the default is empty
##
## .. code-block:: nim
##
##   try:
##     assert("abc".find('c').get() == 2)  # Immediately extract the value
##   except UnpackError:  # If there is no value
##     assert false  # This will not be reached, because the value is present
##
## The ``get`` operation demonstrated above returns the underlying value, or
## raises ``UnpackError`` if there is no value. There is another option for
## obtaining the value: ``unsafeGet``, but you must only use it when you are
## absolutely sure the value is present (e.g. after checking ``isSome``). If
## you do not care about the tiny overhead that ``get`` causes, you should
## simply never use ``unsafeGet``.
##
## How to deal with an absence of a value:
##
## .. code-block:: nim
##
##   let result = "team".find('i')
##
##   # Nothing was found, so the result is `none`.
##   assert(result == none(int))
##   # It has no value:
##   assert(result.isNone)
##
##   try:
##     echo result.get()
##     assert(false)  # This will not be reached
##   except UnpackError:  # Because an exception is raised
##     discard
import typetraits

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

  UnpackError* = ref object of ValueError

proc some*[T](val: T): Option[T] =
  ## Returns a ``Option`` that has this value.
  when T is SomePointer:
    assert val != nil
    result.val = val
  else:
    result.has = true
    result.val = val

proc option*[T](val: T): Option[T] =
  ## Can be used to convert a pointer type to an option type. It
  ## converts ``nil`` to the none-option.
  result.val = val
  when T isnot SomePointer:
    result.has = true

proc none*(T: typedesc): Option[T] =
  ## Returns an ``Option`` for this type that has no value.
  # the default is the none type
  discard

proc none*[T]: Option[T] =
  ## Alias for ``none(T)``.
  none(T)

proc isSome*[T](self: Option[T]): bool {.inline.} =
  when T is SomePointer:
    self.val != nil
  else:
    self.has

proc isNone*[T](self: Option[T]): bool {.inline.} =
  when T is SomePointer:
    self.val == nil
  else:
    not self.has

proc unsafeGet*[T](self: Option[T]): T =
  ## Returns the value of a ``some``. Behavior is undefined for ``none``.
  assert self.isSome
  self.val

proc get*[T](self: Option[T]): T =
  ## Returns contents of the Option. If it is none, then an exception is
  ## thrown.
  if self.isNone:
    raise UnpackError(msg : "Can't obtain a value from a `none`")
  self.val

proc get*[T](self: Option[T], otherwise: T): T =
  ## Returns the contents of this option or `otherwise` if the option is none.
  if self.isSome:
    self.val
  else:
    otherwise

proc map*[T](self: Option[T], callback: proc (input: T)) =
  ## Applies a callback to the value in this Option
  if self.isSome:
    callback(self.val)

proc map*[T, R](self: Option[T], callback: proc (input: T): R): Option[R] =
  ## Applies a callback to the value in this Option and returns an option
  ## containing the new value. If this option is None, None will be returned
  if self.isSome:
    some[R]( callback(self.val) )
  else:
    none(R)

proc flatten*[A](self: Option[Option[A]]): Option[A] =
  ## Remove one level of structure in a nested Option.
  if self.isSome:
    self.val
  else:
    none(A)

proc flatMap*[A, B](self: Option[A], callback: proc (input: A): Option[B]): Option[B] =
  ## Applies a callback to the value in this Option and returns an
  ## option containing the new value. If this option is None, None will be
  ## returned. Similar to ``map``, with the difference that the callback
  ## returns an Option, not a raw value. This allows multiple procs with a
  ## signature of ``A -> Option[B]`` (including A = B) to be chained together.
  map(self, callback).flatten()

proc filter*[T](self: Option[T], callback: proc (input: T): bool): Option[T] =
  ## Applies a callback to the value in this Option. If the callback returns
  ## `true`, the option is returned as a Some. If it returns false, it is
  ## returned as a None.
  if self.isSome and not callback(self.val):
    none(T)
  else:
    self

proc `==`*(a, b: Option): bool =
  ## Returns ``true`` if both ``Option``s are ``none``,
  ## or if they have equal values
  (a.isSome and b.isSome and a.val == b.val) or (not a.isSome and not b.isSome)

proc `$`*[T](self: Option[T]): string =
  ## Get the string representation of this option. If the option has a value,
  ## the result will be `Some(x)` where `x` is the string representation of the contained value.
  ## If the option does not have a value, the result will be `None[T]` where `T` is the name of
  ## the type contained in the option.
  if self.isSome:
    "Some(" & $self.val & ")"
  else:
    "None[" & T.name & "]"

when isMainModule:
  import unittest, sequtils

  suite "options":
    # work around a bug in unittest
    let intNone = none(int)
    let stringNone = none(string)

    test "example":
      proc find(haystack: string, needle: char): Option[int] =
        for i, c in haystack:
          if c == needle:
            return some i

      check("abc".find('c').get() == 2)

      let result = "team".find('i')

      check result == intNone
      check result.isNone

    test "some":
      check some(6).get() == 6
      check some("a").unsafeGet() == "a"
      check some(6).isSome
      check some("a").isSome

    test "none":
      expect UnpackError:
        discard none(int).get()
      check(none(int).isNone)
      check(not none(string).isSome)

    test "equality":
      check some("a") == some("a")
      check some(7) != some(6)
      check some("a") != stringNone
      check intNone == intNone

      when compiles(some("a") == some(5)):
        check false
      when compiles(none(string) == none(int)):
        check false

    test "get with a default value":
      check(some("Correct").get("Wrong") == "Correct")
      check(stringNone.get("Correct") == "Correct")

    test "$":
      check($(some("Correct")) == "Some(Correct)")
      check($(stringNone) == "None[string]")

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

    test "SomePointer":
      var intref: ref int
      check(option(intref).isNone)
      intref.new
      check(option(intref).isSome)

      let tmp = option(intref)
      check(sizeof(tmp) == sizeof(ptr int))

    test "none[T]":
      check(none[int]().isNone)
      check(none(int) == none[int]())
