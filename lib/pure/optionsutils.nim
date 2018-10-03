#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module, previously a part of ``options``, implements some more advanced
## ways to interact with options. It includes conditional mapping of procedures
## over an option, flattening of nested options, and filtering of values within
## options. It also includes an existential operator that works like regular
## dot-chaining but stops if the left hand side is a none-option.

import options, macros

proc map*[T](self: Option[T], callback: proc (input: T)) =
  ## Applies a callback to the value in this Option
  if self.isSome:
    callback(self.unsafeGet)

proc map*[T, R](self: Option[T], callback: proc (input: T): R): Option[R] =
  ## Applies a callback to the value in this Option and returns an option
  ## containing the new value. If this option is None, None will be returned
  if self.isSome:
    some[R]( callback(self.unsafeGet) )
  else:
    none(R)

proc flatten*[A](self: Option[Option[A]]): Option[A] =
  ## Remove one level of structure in a nested Option.
  if self.isSome:
    self.unsafeGet
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
  if self.isSome and not callback(self.unsafeGet):
    none(T)
  else:
    self

macro `?.`*(option: untyped, statements: untyped): untyped =
  ## Existential operator. Works like regular dot-chaining, but if
  ## the left had side is a ``none`` then the right hand side is not evaluated.
  ## In the case that ``statements`` return something the return type of this
  ## will be ``Option[T]`` where ``T`` is the returned type of ``statements``.
  ## If nothing is returned from ``statements`` this returns nothing.
  ##
  ## .. code-block:: nim
  ##   echo some("Hello")?.find('l') ## Prints out Some(2)
  ##   some("Hello")?.find('l').echo # Prints out 2
  ##   none(string)?.find('l').echo # Doesn't print out anything
  ##   echo none(string)?.find('l') # Prints out None[int] (return type of find)
  ##   # These also work in things like ifs
  ##   if some("Hello")?.find('l') == 2:
  ##     echo "This prints"
  ##   if none(string)?.find('l') == 2:
  ##     echo "This doesn't"
  let opt = genSym(nskLet)
  var
    injected = statements
    firstBarren = statements
  if firstBarren.len != 0:
    while true:
      if firstBarren[0].len == 0:
        firstBarren[0] = nnkDotExpr.newTree(
          nnkDotExpr.newTree(opt, newIdentNode("unsafeGet")), firstBarren[0])
        break
      firstBarren = firstBarren[0]
  else:
    injected = nnkDotExpr.newTree(
      nnkDotExpr.newTree(opt, newIdentNode("unsafeGet")), firstBarren)

  result = quote do:
    (proc (): auto =
      let `opt` = `option`
      if `opt`.isSome:
        when compiles(`injected`) and not compiles(some(`injected`)):
          `injected`
        else:
          return some(`injected`)
    )()

when isMainModule:
  import unittest, sequtils

  suite "optionsutils":
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

    test "existential operator":
      when not compiles(some("Hello world")?.find('w').echo):
        check false
      check (some("Hello world")?.find('w')).unsafeGet == 6
      var evaluated = false
      if (some("team")?.find('i')).unsafeGet == -1:
        evaluated = true
      check evaluated == true
      evaluated = false
      if (none(string)?.find('i')).isSome:
        evaluated = true
      check evaluated == false

