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
## This can be useful when you have a value that can be present or not.  The
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
##   import optionals
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
  Option*[T] = object
    ## An optional type that stores its value and state separately in a boolean.
    val: T
    has: bool
  UnpackError* = ref object of ValueError


proc some*[T](val: T): Option[T] =
  ## Returns a ``Option`` that has this value.
  result.has = true
  result.val = val

proc none*(T: typedesc): Option[T] =
  ## Returns a ``Option`` for this type that has no value.
  result.has = false


proc isSome*[T](self: Option[T]): bool =
  self.has

proc isNone*[T](self: Option[T]): bool =
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


proc `==`*(a, b: Option): bool =
  ## Returns ``true`` if both ``Option``s are ``none``,
  ## or if they have equal values
  (a.has and b.has and a.val == b.val) or (not a.has and not b.has)


when isMainModule:
  import unittest

  suite "optionals":
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
