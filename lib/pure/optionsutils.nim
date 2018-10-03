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
## options. Along with this it also contains a macro to enforce a safe unpacking
## pattern for options.

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

