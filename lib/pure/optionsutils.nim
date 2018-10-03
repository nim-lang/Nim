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
## options. It also contains macros for wrapping procedures that return an error
## code or throw an exception into one that returns an option instead for
## use with other option based things.

import options

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

macro wrapCall*(statement: untyped): untyped =
  ## Macro that wraps a procedure which can throw an exception into one that
  ## returns an option. This version takes a procedure with arguments and a
  ## return type. It returns a lambda that has the same signature as the
  ## procedure but returns an Option of the return type. The body executes the
  ## statement and returns the value if there is no exception, otherwise it
  ## returns a none option.
  ##
  ## .. code-block:: nim
  ##   let optParseInt = wrapCall: parseInt(x: string): int
  ##   echo optParseInt("10") # Prints "some(10)"
  ##   echo optParseInt("bob") # Prints "none(int)"
  assert(statement.kind == nnkStmtList)
  assert(statement[0].kind == nnkCall)
  assert(statement[0].len == 2)
  assert(statement[0][0].kind == nnkObjConstr)
  assert(statement[0][0].len >= 1)
  assert(statement[0][0][0].kind == nnkIdent)
  for i in 1 ..< statement[0][0].len:
    assert(statement[0][0][i].kind == nnkExprColonExpr)
    assert(statement[0][0][i].len == 2)
    assert(statement[0][0][i][0].kind == nnkIdent)
  assert(statement[0][1].kind == nnkStmtList)
  let T = statement[0][1][0]
  let
    procName = statement[0][0][0]
  result = quote do:
    (proc (): Option[`T`] =
      try:
        return some(`procName`())
      except:
        return none[`T`]()
    )
  # Add the arguments to the argument list of the proc and the call
  for i in 1 ..< statement[0][0].len:
    result[0][3].add nnkIdentDefs.newTree(statement[0][0][i][0], statement[0][0][i][1], newEmptyNode())
    result[0][6][0][0][0][0][1].add statement[0][0][i][0]

macro wrapException*(statement: untyped): untyped =
  ## Macro that wraps a procedure which can throw an exception into one that
  ## returns an option. This version takes a procedure with arguments but no
  ## return type. It returns a lambda that has the same signature as the
  ## procedure but returns an ``Option[ref Exception]``. The body executes the
  ## statement and returns a none option if there is no exception. Otherwise it
  ## returns a some option with the exception.
  ##
  ## .. code-block:: nim
  ##   let optParseInt = wrapException: parseInt(x: string)
  ##   allSome optParseInt("bob"):
  ##     just e: echo e.msg
  ##     none: echo "Execution succeded"
  assert(statement.len == 1)
  assert(statement[0].kind == nnkObjConstr)
  assert(statement[0].len >= 1)
  assert(statement[0][0].kind == nnkIdent)
  for i in 1 ..< statement[0].len:
    assert(statement[0][i].kind == nnkExprColonExpr)
    assert(statement[0][i].len == 2)
    assert(statement[0][i][0].kind == nnkIdent)
  let
    procName = statement[0][0]
  result = quote do:
    (proc (): Option[ref Exception] =
      try:
        discard `procName`()
        return none(ref Exception)
      except:
        return some(getCurrentException())
    )
  # Add the arguments to the argument list of the proc and the call
  for i in 1 ..< statement[0].len:
    result[0][3].add nnkIdentDefs.newTree(statement[0][i][0], statement[0][i][1], newEmptyNode())
    result[0][6][0][0][0][0].add statement[0][i][0]

macro wrapErrorCode*(statement: untyped): untyped =
  ## Macro that wraps a procedure which returns an error code into one that
  ## returns an option. This version takes a procedure with arguments but no
  ## return type. It returns a lambda that has the same signature as the
  ## procedure but returns an ``Option[int]``. The body executes the
  ## statement and returns a none option if the error code is 0. Otherwise it
  ## returns a some option with the error code.
  ##
  ## .. code-block:: nim
  ##   # We cheat a bit here and use parseInt to emulate an error code
  ##   let optParseInt = wrapErrorCode: parseInt(x: string)
  ##   allSome optParseInt("10"):
  ##     just e: echo "Got error code: ", e
  ##     none: echo "Execution succeded"
  assert(statement.len == 1)
  assert(statement[0].kind == nnkObjConstr)
  assert(statement[0].len >= 1)
  assert(statement[0][0].kind == nnkIdent)
  for i in 1 ..< statement[0].len:
    assert(statement[0][i].kind == nnkExprColonExpr)
    assert(statement[0][i].len == 2)
    assert(statement[0][i][0].kind == nnkIdent)
  let
    procName = statement[0][0]
  result = quote do:
    (proc (): Option[int] =
      let eCode = `procName`()
      if eCode == 0:
        return none(int)
      else:
        return some(eCode)
    )
  # Add the arguments to the argument list of the proc and the call
  for i in 1 ..< statement[0].len:
    result[0][3].add nnkIdentDefs.newTree(statement[0][i][0], statement[0][i][1], newEmptyNode())
    result[0][6][0][0][2].add statement[0][i][0]

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


