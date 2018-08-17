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
## This module expands the usability of options with several practical patters
## and procedures. The goal is to make it safer and more ergonomic to use options
## and to handle optional values.
##
## Tutorial
## ========
##
## Let's start with the same example as in the options module: a procedure that
## finds the index of a character in a string.
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
##   allSome "abc".find('c'):
##     some x: assert(x == 2)
##     none: assert false # This will not be reached, because the string
##                        # contains 'c'
##
## This pattern assures that you only access the value of on option in a safe
## way. This is by far the safest and simplest way to use an option value. It
## can take either a single statement as seen above, or multiple. Note that
## ``allSome`` will not evaluate all statements if an earlier one doesn't return
## a value:
##
## .. code-block:: nim
##   let msg = allSome([none(int), some(200)]):
##     some [x, _]: "First value is " & $x
##     none: "No value"
##   echo msg # This will echo "No value"
##
## In this block the call to ``some(200)`` is never executed, so it's safe to
## put a list of expensive operations in a block like this.
##
## As seen above you can also ignore the value of an option by using an
## underscore as the identifier. But if you want to assign it to a locally
## available symbol simply add it in the same position in the list. The
## underscore can be used to ignore one value, the entire list of values, or
## only some of the values.
##
## This module also implements common mapping functionality to use a procedure
## on an optional value, carrying over the absence state if there is no value:
##
## .. code-block:: nim
##
##   let
##     x = some(10)
##     y = none(int)
##   assert(map(x, proc(x: int): int = x + 10) == some(20))
##   assert(map(y, proc(x: int): int = x + 10).isNone)
##
## Options can also be used for conditional chaining with the `.?` operator.
## Let's use the ``find`` procedure we defined above:
##
## .. code-block:: nim
##   var position = "hello world".find('w')
##   echo position # echoes out Some(6) as expected
##   position = "hello world".find('w').?min(4)
##   echo position # echoes out Some(4), we take the minimum of 6 and 4
##   position = "hello world".find('q').?min(4)
##   echo position # echoes out None[int], min is never run since find returns
##   # a none option.
##   position = "hello world".find('w').?min(4).max(0)
##   echo position # echoes out Some(4) both min and max are run
##   position = "hello world".find('q').?min(4).max(0)
##   echo position # echoes out None[int], min and max is never run
##
## Since options use their has-ity as their boolean value this chaining can
## also be used in if statements:
##
## .. code-block:: nim
##   if ("hello world".find('w').?min(4)).isSome:
##     echo "Never run"
import options
import macros

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

proc flatMap*[A, B](self: Option[A], callback: proc (input: A): Option[B]):
  Option[B] =
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

macro `.?`*(option: untyped, statements: untyped): untyped =
  ## Optional continuation operator. Works like regular dot-chaining, but if
  ## the left had side is a ``none`` then the right hand side is not evaluated.
  ## In the case that ``statements`` return something the return type of this
  ## will be ``Option[T]`` where ``T`` is the returned type of ``statements``.
  ## If nothing is returned from ``statements`` this returns nothing.
  ##
  ## .. code-block:: nim
  ##   echo some("Hello").?find('l') ## Prints out Some(2)
  ##   some("Hello").?find('l').echo # Prints out 2
  ##   none(string).?find('l').echo # Doesn't print out anything
  ##   echo none(string).?find('l') # Prints out None[int] (return type of find)
  ##   # These also work in things like ifs
  ##   if some("Hello").?find('l') == 2:
  ##     echo "This prints"
  ##   if none(string).?find('l') == 2:
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

  #echo result.treerepr

macro allSome*(options: untyped, body: untyped): untyped =
  ## Macro to require a set of options to have a value. This macro takes one or
  ## more statements that returns an option, and two cases for how to handle
  ## the cases that all the options have a value or that at least one of them
  ## doesn't. The easiest example looks something like this:
  ##
  ## .. code-block:: nim
  ##   allSome "abc".find('b'):
  ##     some pos: echo "Found 'b' at position: ", pos
  ##     none: echo "Couldn't find b"
  ##
  ## In order to minimize the nesting of these allSome blocks you can pass a
  ## list of statements that return an option to require and a list of
  ## identifiers to the ``some`` case. When doing this the statements will be
  ## executed one by one, terminating before all statements are evaluated if one
  ## doesn't return a ``some`` option:
  ##
  ## .. code-block:: nim
  ##   allSome ["abc".find('o'), "def".find('f')]:
  ##     some [firstPos, secondPos]:
  ##       echo "Found 'o' at position: ", firstPos, " and 'f' at position ",
  ##         secondPos
  ##     none: echo "Couldn't find either 'o' or 'f'"
  ##
  ## This will search for an "o" in the string "abc" which will return a
  ## ``none`` option and so we will stop, not search for "f" and run
  ## the ``none`` case. If there are any of the values we don't care about, but
  ## we still require them to exist we can shadow the identifier. All of these
  ## would be valid (this is just an example, it is not allowed to have more
  ## than one ``some`` case):
  ##
  ## .. code-block:: nim
  ##   allSome [oneThing, anotherThing]:
  ##     some [firstPos, secondPos]:
  ##     some [_, secondPos]:
  ##     some _:
  ##   allSome [oneThing]:
  ##     some pos:
  ##     some _:
  ##
  ## A allSome block can also be used to return values:
  ##
  ## .. code-block:: nim
  ##   let x = allSome(["abc".find('b'), "def".find('f')]):
  ##     some [firstPos, secondPos]: firstPos + secondPos
  ##     none: -1
  ##   echo x # Prints out "3" (1 + 2)
  var
    noneCase: NimNode = nil
    someCase: NimNode = nil
    idents: NimNode = nil
  for optionCase in body:
    case optionCase.kind:
    of nnkCall:
      if $optionCase[0] != "none":
        if $optionCase[0] != "some":
          error "Only \"none\" and \"some\" are allowed as case labels",
            optionCase[0]
        else:
          error "Only \"none\" is allowed to not have arguments", optionCase[0]
      elif noneCase != nil:
        error "Only one \"none\" case is allowed, " &
          "previously defined \"none\" case at: " & lineInfo(noneCase),
          optionCase[0]
      else:
        noneCase = optionCase[1]
    of nnkCommand:
      if $optionCase[0] != "some":
        if $optionCase[0] != "none":
          error "Only \"none\" and \"some\" are allowed as case labels",
            optionCase[0]
        else:
          error "Only \"some\" is allowed to have arguments", optionCase[0]
      else:
        if optionCase[1].kind != nnkBracket and optionCase[1].kind != nnkIdent:
          error "Must have either a list or a single identifier as arguments",
            optionCase[1]
        else:
          if optionCase[1].kind == nnkBracket:
            if options.kind != nnkBracket:
              error "When only a single option is passed only a single " &
                "identifier must be supplied", optionCase[1]
            for i in optionCase[1]:
              if i.kind != nnkIdent:
                error "List must only contain identifiers", i
          elif options.kind == nnkBracket:
            if $optionCase[1] != "_":
              error "When multiple options is passed all identifiers must be " &
                "supplied", optionCase[1]
          idents = if optionCase[1].kind == nnkBracket: optionCase[1] else: newStmtList(optionCase[1])
          someCase = optionCase[2]
    else:
      error "Unrecognized structure of cases", optionCase
  if noneCase == nil:
    error "Must have a \"none\" case"
  if someCase == nil:
    error "Must have a \"some\" case"
  var body = someCase
  let optionsList = (if options.kind == nnkBracket: options else: newStmtList(options))
  for i in countdown(optionsList.len - 1, 0):
    let
      option = optionsList[i]
      tmpLet = genSym(nskLet)
      ident = if idents.len <= i: newLit("_") else: idents[i]
      assign = if $ident != "_":
        quote do:
          let `ident` = `tmpLet`.unsafeGet
      else:
        newStmtList()
    body = quote do:
      let `tmpLet` = `option`
      if `tmpLet`.isSome:
        `assign`
        `body`
      else:
        `noneCase`
  result = quote do:
    (proc (): auto =
      `body`
    )()
  #echo result.repr

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
  import unittest, sequtils, strutils

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
      check (some(123).map(proc (v: int): int = v * 2)).unsafeGet == 246
      check(intNone.map(proc (v: int): int = v * 2).isNone)

    test "filter":
      check (some(123).filter(proc (v: int): bool = v == 123)).unsafeGet == 123
      check some(456).filter(proc (v: int): bool = v == 123).isNone
      check intNone.filter(proc (v: int): bool = check false).isNone

    test "flatMap":
      proc addOneIfNotZero(v: int): Option[int] =
        if v != 0:
          result = some(v + 1)
        else:
          result = none(int)

      check (some(1).flatMap(addOneIfNotZero)).unsafeGet == 2
      check some(0).flatMap(addOneIfNotZero).isNone
      check (some(1).flatMap(addOneIfNotZero).flatMap(addOneIfNotZero)).unsafeGet == 3

      proc maybeToString(v: int): Option[string] =
        if v != 0:
          result = some($v)
        else:
          result = none(string)

      check (some(1).flatMap(maybeToString)).unsafeGet == "1"

      proc maybeExclaim(v: string): Option[string] =
        if v != "":
          result = some v & "!"
        else:
          result = none(string)

      check (some(1).flatMap(maybeToString).flatMap(maybeExclaim)).unsafeGet == "1!"
      check(some(0).flatMap(maybeToString).flatMap(maybeExclaim).isNone)

    test "allSome":
      let x = some(100)
      allSome x:
        some y:
          check y == 100
        none: discard

      var res = allSome(none(int)) do:
        some _: "Hello"
        none: "No value"

      check res == "No value"

      var echoed = ""
      proc mockEcho(input: varargs[string, `$`]) =
        echoed = input[0]
        for i in 1..input.high:
          echoed = echoed & input[i]

      allSome some(100):
        some x: mockEcho "Is hundred"
        none: mockEcho "No value"

      check echoed == "Is hundred"

      var sideEffects = 0
      proc someWithSideEffect(): Option[int] =
        sideEffects += 1
        some(100)

      allSome([none(int), someWithSideEffect()]):
        some [x, _]: mockEcho x
        none: mockEcho "No value"

      check echoed == "No value"
      check sideEffects == 0

      let y = allSome([some(100), someWithSideEffect(), some(3)]):
        some [x, y, z]: (x + y) * z
        none: 0

      check y == 600
      check sideEffects == 1

      allSome([some(100), some(200)]):
        some _: mockEcho "Has value"
        none: mockEcho "No value"

      check echoed == "Has value"

      type NonCaseAble = object
        val: string
      allSome some(NonCaseAble(val: "hello world")):
        some x: mockEcho x.val
        none: mockEcho "No value"

      check echoed == "hello world"

    test "conditional continuation":
      when not compiles(some("Hello world").?find('w').echo):
        check false
      check (some("Hello world").?find('w')).unsafeGet == 6
      var evaluated = false
      if (some("team").?find('i')).unsafeGet == -1:
        evaluated = true
      check evaluated == true
      evaluated = false
      if (none(string).?find('i')).isSome:
        evaluated = true
      check evaluated == false

    test "wrap call":
      let optParseInt = wrapCall: parseInt(x: string): int
      check (optParseInt("10")).unsafeGet == 10
      check optParseInt("bob").isNone

    test "wrap exception":
      let optParseInt = wrapException: parseInt(x: string)
      check optParseInt("10").isNone
      check (optParseInt("bob").?msg).unsafeGet == "invalid integer: bob"

    test "wrap error codes":
      # We cheat and use parseInt to return an "error code"
      let optParseInt = wrapErrorCode: parseInt(x: string)
      check optParseInt("10").isSome
      check optParseInt("0").isNone

