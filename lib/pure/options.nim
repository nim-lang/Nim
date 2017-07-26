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

proc get*[T](self: Option[T], otherwise: T): T =
  ## Returns the contents of this option or `otherwise` if the option is none.
  if self.isSome:
    self.val
  else:
    otherwise


proc map*[T](self: Option[T], callback: proc (input: T)) =
  ## Applies a callback to the value in this Option
  if self.has:
    callback(self.val)

proc map*[T, R](self: Option[T], callback: proc (input: T): R): Option[R] =
  ## Applies a callback to the value in this Option and returns an option
  ## containing the new value. If this option is None, None will be returned
  if self.has:
    some[R]( callback(self.val) )
  else:
    none(R)

proc filter*[T](self: Option[T], callback: proc (input: T): bool): Option[T] =
  ## Applies a callback to the value in this Option. If the callback returns
  ## `true`, the option is returned as a Some. If it returns false, it is
  ## returned as a None.
  if self.has and not callback(self.val):
    none(T)
  else:
    self


proc `==`*(a, b: Option): bool =
  ## Returns ``true`` if both ``Option``s are ``none``,
  ## or if they have equal values
  (a.has and b.has and a.val == b.val) or (not a.has and not b.has)


proc `$`*[T]( self: Option[T] ): string =
  ## Returns the contents of this option or `otherwise` if the option is none.
  if self.has:
    "Some(" & $self.val & ")"
  else:
    "None[" & T.name & "]"


template `??`*[T](left: T, right: T): T =
  ## Returns ``left`` if not nil or ``right`` otherwise.
  when not compiles(isNil(left)):
    left
  else:
    if not isNil(left): left else: right

template `??`*[T](left: T, right: Option[T]): Option[T] =
  ## Returns ``left`` as an option if not nil or ``right`` otherwise.
  when not compiles(isNil(left)):
    some(left)
  else:
    if not isNil(left): some(left) else: right

template `??`*[T](left: Option[T], right: T): T =
  ## Returns the contents of ``left`` if exists and not nil or ``right`` otherwise.
  if isSome(left): left.get() ?? right else: right

template `??`*[T](left: Option[T], right: Option[T]): Option[T] =
  ## Returns ``left`` if exists and not nil or ``right`` otherwise.
  if isSome(left): left.get() ?? right else: right


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
      check( some("Correct").get("Wrong") == "Correct" )
      check( stringNone.get("Correct") == "Correct" )

    test "$":
      check( $(some("Correct")) == "Some(Correct)" )
      check( $(stringNone) == "None[string]" )

    test "map with a void result":
      var procRan = 0
      some(123).map(proc (v: int) = procRan = v)
      check procRan == 123
      intNone.map(proc (v: int) = check false)

    test "map":
      check( some(123).map(proc (v: int): int = v * 2) == some(246) )
      check( intNone.map(proc (v: int): int = v * 2).isNone )

    test "filter":
      check( some(123).filter(proc (v: int): bool = v == 123) == some(123) )
      check( some(456).filter(proc (v: int): bool = v == 123).isNone )
      check( intNone.filter(proc (v: int): bool = check false).isNone )

  suite "coalesce":
    template `==`[T](left: Option[T], right: T): bool =
      if isSome(left): left.get() == right else: false

    template `==`[T](left: T, right: Option[T]): bool =
      right == left

    suite "coalesce option and option":
      test "left some":
        let a: Option[string] = some("a")
        let b: Option[string] = none(string)
        check((a ?? b) == a)
      test "left none":
        let a: Option[string] = none(string)
        let b: Option[string] = some("b")
        check((a ?? b) == b)
      test "left some nil":
        let a: Option[string] = some(string(nil))
        let b: Option[string] = some("b")
        check((a ?? b) == b)
      test "left not nillable":
        let a: Option[int] = some(0)
        let b: Option[int] = some(1)
        check((a ?? b) == a)

    suite "coalesce option and raw":
      test "left some":
        let a: Option[string] = some("a")
        let b: string = "b"
        check((a ?? b) == a)
      test "left none":
        let a: Option[string] = none(string)
        let b: string = "b"
        check((a ?? b) == b)
      test "left some nil":
        let a: Option[string] = some(string(nil))
        let b: string = "b"
        check((a ?? b) == b)

    suite "coalesce raw and option":
      test "left not nil":
        let a: string = "a"
        let b: Option[string] = none(string)
        check((a ?? b) == a)
      test "left nil":
        let a: string = nil
        let b: Option[string] = some("b")
        check((a ?? b) == b)

    suite "coalesce raw and raw":
      test "left not nil":
        let a: string = "a"
        let b: string = nil
        check((a ?? b) == a)
      test "left nil":
        let a: string = nil
        let b: string = "b"
        check((a ?? b) == b)
      test "left not nillable":
        let a: int = 0
        let b: int = 1
        check((a ?? b) == a)

    suite "coalesce options and raw":
      test "first some":
        let a: Option[string] = some("a")
        let b: Option[string] = some("b")
        let c: string = "c"
        check((a ?? b ?? c) == a)
      test "second some":
        let a: Option[string] = none(string)
        let b: Option[string] = some("b")
        let c: string = "c"
        check((a ?? b ?? c) == b)
      test "both none":
        let a: Option[string] = none(string)
        let b: Option[string] = none(string)
        let c: string = "c"
        check((a ?? b ?? c) == c)

    suite "coalesce option and raws":
      test "first some":
        let a: Option[string] = some("a")
        let b: string = "b"
        let c: string = "c"
        check((a ?? b ?? c) == a)
      test "first none, second not nil":
        let a: Option[string] = none(string)
        let b: string = "b"
        let c: string = "c"
        check((a ?? b ?? c) == b)
      test "first none, second nil":
        let a: Option[string] = none(string)
        let b: string = nil
        let c: string = "c"
        check((a ?? b ?? c) == c)

    suite "coalesce raw and options":
      test "first not nil":
        let a: string = "a"
        let b: Option[string] = some("b")
        let c: Option[string] = some("c")
        check((a ?? b ?? c) == a)
      test "first nil, second some":
        let a: string = nil
        let b: Option[string] = some("b")
        let c: Option[string] = some("c")
        check((a ?? b ?? c) == b)
      test "first nil, second none":
        let a: string = nil
        let b: Option[string] = none(string)
        let c: Option[string] = some("c")
        check((a ?? b ?? c) == c)

    suite "coalesce raws and option":
      test "first not nil":
        let a: string = "a"
        let b: string = "b"
        let c: Option[string] = some("c")
        check((a ?? b ?? c) == a)
      test "first nil, second not nil":
        let a: string = nil
        let b: string = "b"
        let c: Option[string] = some("c")
        check((a ?? b ?? c) == b)
      test "first nil, second nil":
        let a: string = nil
        let b: string = nil
        let c: Option[string] = some("c")
        check((a ?? b ?? c) == c)

    suite "short circuit options":
      test "first some":
        proc getA(): Option[string] = return some("a")
        proc getB(): Option[string] = raise newException(ValueError, "expensive operation")
        discard getA() ?? getB()
      test "first none":
        proc getA(): Option[string] = return none(string)
        proc getB(): Option[string] = raise newException(ValueError, "expensive operation")
        expect ValueError:
          discard getA() ?? getB()

    suite "short circuit raws":
      test "first not nil":
        proc getA(): string = return "a"
        proc getB(): string = raise newException(ValueError, "expensive operation")
        discard getA() ?? getB()
      test "first nil":
        proc getA(): string = return nil
        proc getB(): string = raise newException(ValueError, "expensive operation")
        expect ValueError:
          discard getA() ?? getB()
