#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

##[
This module implements types which encapsulate an optional value.

A value of type `Option[T]` either contains a value `x` (represented as
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
  proc find(haystack: string, needle: char): Option[int] =
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
Instead, rely on checking if the option contains a value with the
`isSome <#isSome,Option[T]>`_ and `isNone <#isNone,Option[T]>`_ procs.


Pattern matching
================

.. note:: This requires the [fusion](https://github.com/nim-lang/fusion) package.

[fusion/matching](https://nim-lang.github.io/fusion/src/fusion/matching.html)
supports pattern matching on `Option`s, with the `Some(<pattern>)` and
`None()` patterns.

  ```nim
  {.experimental: "caseStmtMacros".}

  import fusion/matching

  case some(42)
  of Some(@a):
    assert a == 42
  of None():
    assert false

  assertMatch(some(some(none(int))), Some(Some(None())))
  ```
]##
# xxx pending https://github.com/timotheecour/Nim/issues/376 use `runnableExamples` and `whichModule`

when defined(nimHasEffectsOf):
  {.experimental: "strictEffects".}
else:
  {.pragma: effectsOf.}

import std/[typetraits, macros]

when defined(nimPreviewSlimSystem):
  import std/assertions


when (NimMajor, NimMinor) >= (1, 1):
  type
    SomePointer = ref | ptr | pointer | proc | iterator {.closure.}
else:
  type
    SomePointer = ref | ptr | pointer

type
  Option*[T] = object
    ## An optional type that may or may not contain a value of type `T`.
    ## When `T` is a a pointer type (`ptr`, `pointer`, `ref`, `proc` or `iterator {.closure.}`),
    ## `none(T)` is represented as `nil`.
    when T is SomePointer:
      val: T
    else:
      val: T
      has: bool

  UnpackDefect* = object of Defect
  UnpackError* {.deprecated: "See corresponding Defect".} = UnpackDefect

proc option*[T](val: sink T): Option[T] {.inline.} =
  ## Can be used to convert a pointer type (`ptr`, `pointer`, `ref` or `proc`) to an option type.
  ## It converts `nil` to `none(T)`. When `T` is no pointer type, this is equivalent to `some(val)`.
  ##
  ## **See also:**
  ## * `some proc <#some,T>`_
  ## * `none proc <#none,typedesc>`_
  runnableExamples:
    type
      Foo = ref object
        a: int
        b: string

    assert option[Foo](nil).isNone
    assert option(42).isSome

  when T is SomePointer:
    result = Option[T](val: val)
  else:
    result = Option[T](has: true, val: val)

proc some*[T](val: sink T): Option[T] {.inline.} =
  ## Returns an `Option` that has the value `val`.
  ##
  ## **See also:**
  ## * `option proc <#option,T>`_
  ## * `none proc <#none,typedesc>`_
  ## * `isSome proc <#isSome,Option[T]>`_
  runnableExamples:
    let a = some("abc")

    assert a.isSome
    assert a.get == "abc"

  when T is SomePointer:
    assert not val.isNil
    result = Option[T](val: val)
  else:
    result = Option[T](has: true, val: val)

proc none*(T: typedesc): Option[T] {.inline.} =
  ## Returns an `Option` for this type that has no value.
  ##
  ## **See also:**
  ## * `option proc <#option,T>`_
  ## * `some proc <#some,T>`_
  ## * `isNone proc <#isNone,Option[T]>`_
  runnableExamples:
    assert none(int).isNone

  # the default is the none type
  result = Option[T]()

proc none*[T]: Option[T] {.inline.} =
  ## Alias for `none(T) <#none,typedesc>`_.
  none(T)

proc isSome*[T](self: Option[T]): bool {.inline.} =
  ## Checks if an `Option` contains a value.
  ##
  ## **See also:**
  ## * `isNone proc <#isNone,Option[T]>`_
  ## * `some proc <#some,T>`_
  runnableExamples:
    assert some(42).isSome
    assert not none(string).isSome

  when T is SomePointer:
    not self.val.isNil
  else:
    self.has

proc isNone*[T](self: Option[T]): bool {.inline.} =
  ## Checks if an `Option` is empty.
  ##
  ## **See also:**
  ## * `isSome proc <#isSome,Option[T]>`_
  ## * `none proc <#none,typedesc>`_
  runnableExamples:
    assert not some(42).isNone
    assert none(string).isNone

  when T is SomePointer:
    self.val.isNil
  else:
    not self.has

proc get*[T](self: Option[T]): lent T {.inline.} =
  ## Returns the content of an `Option`. If it has no value,
  ## an `UnpackDefect` exception is raised.
  ##
  ## **See also:**
  ## * `get proc <#get,Option[T],T>`_ with a default return value
  runnableExamples:
    assert some(42).get == 42
    doAssertRaises(UnpackDefect):
      echo none(string).get

  if self.isNone:
    raise newException(UnpackDefect, "Can't obtain a value from a `none`")
  result = self.val

proc get*[T](self: Option[T], otherwise: T): T {.inline.} =
  ## Returns the content of the `Option` or `otherwise` if
  ## the `Option` has no value.
  runnableExamples:
    assert some(42).get(9999) == 42
    assert none(int).get(9999) == 9999

  if self.isSome:
    self.val
  else:
    otherwise

proc get*[T](self: var Option[T]): var T {.inline.} =
  ## Returns the content of the `var Option` mutably. If it has no value,
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

proc map*[T](self: Option[T], callback: proc (input: T)) {.inline, effectsOf: callback.} =
  ## Applies a `callback` function to the value of the `Option`, if it has one.
  ##
  ## **See also:**
  ## * `map proc <#map,Option[T],proc(T)_2>`_ for a version with a callback
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

proc map*[T, R](self: Option[T], callback: proc (input: T): R): Option[R] {.inline, effectsOf: callback.} =
  ## Applies a `callback` function to the value of the `Option` and returns an
  ## `Option` containing the new value.
  ##
  ## If the `Option` has no value, `none(R)` will be returned.
  ##
  ## **See also:**
  ## * `map proc <#map,Option[T],proc(T)>`_
  ## * `flatMap proc <#flatMap,Option[T],proc(T)>`_ for a version with a
  ##   callback that returns an `Option`
  runnableExamples:
    proc isEven(x: int): bool =
      x mod 2 == 0

    assert some(42).map(isEven) == some(true)
    assert none(int).map(isEven) == none(bool)

  if self.isSome:
    some[R](callback(self.val))
  else:
    none(R)

proc flatten*[T](self: Option[Option[T]]): Option[T] {.inline.} =
  ## Remove one level of structure in a nested `Option`.
  ##
  ## **See also:**
  ## * `flatMap proc <#flatMap,Option[T],proc(T)>`_
  runnableExamples:
    assert flatten(some(some(42))) == some(42)
    assert flatten(none(Option[int])) == none(int)

  if self.isSome:
    self.val
  else:
    none(T)

proc flatMap*[T, R](self: Option[T],
                    callback: proc (input: T): Option[R]): Option[R] {.inline, effectsOf: callback.} =
  ## Applies a `callback` function to the value of the `Option` and returns the new value.
  ##
  ## If the `Option` has no value, `none(R)` will be returned.
  ##
  ## This is similar to `map`, with the difference that the `callback` returns an
  ## `Option`, not a raw value. This allows multiple procs with a
  ## signature of `A -> Option[B]` to be chained together.
  ##
  ## See also:
  ## * `flatten proc <#flatten,Option[Option[A]]>`_
  ## * `filter proc <#filter,Option[T],proc(T)>`_
  runnableExamples:
    proc doublePositives(x: int): Option[int] =
      if x > 0:
        some(2 * x)
      else:
        none(int)

    assert some(42).flatMap(doublePositives) == some(84)
    assert none(int).flatMap(doublePositives) == none(int)
    assert some(-11).flatMap(doublePositives) == none(int)

  map(self, callback).flatten()

proc filter*[T](self: Option[T], callback: proc (input: T): bool): Option[T] {.inline, effectsOf: callback.} =
  ## Applies a `callback` to the value of the `Option`.
  ##
  ## If the `callback` returns `true`, the option is returned as `some`.
  ## If it returns `false`, it is returned as `none`.
  ##
  ## **See also:**
  ## * `flatMap proc <#flatMap,Option[A],proc(A)>`_
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

proc `==`*[T](a, b: Option[T]): bool {.inline.} =
  ## Returns `true` if both `Option`s are `none`,
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

  when T is SomePointer:
    a.val == b.val
  else:
    (a.isSome and b.isSome and a.val == b.val) or (a.isNone and b.isNone)

proc `$`*[T](self: Option[T]): string =
  ## Get the string representation of the `Option`.
  runnableExamples:
    assert $some(42) == "some(42)"
    assert $none(int) == "none(int)"

  if self.isSome:
    when defined(nimLagacyOptionsDollar):
      result = "Some("
    else:
      result = "some("
    result.addQuoted self.val
    result.add ")"
  else:
    when defined(nimLagacyOptionsDollar):
      result = "None[" & name(T) & "]"
    else:
      result = "none(" & name(T) & ")"

proc unsafeGet*[T](self: Option[T]): lent T {.inline.}=
  ## Returns the value of a `some`. The behavior is undefined for `none`.
  ##
  ## **Note:** Use this only when you are **absolutely sure** the value is present
  ## (e.g. after checking with `isSome <#isSome,Option[T]>`_).
  ## Generally, using the `get proc <#get,Option[T]>`_ is preferred.
  assert self.isSome
  result = self.val

macro evalOnceAs(expAlias, exp: untyped): untyped =
  ## Injects `expAlias` in caller scope, evaluating it only once and ensuring no copies are made.
  expectKind(expAlias, nnkIdent)
  return if exp.kind != nnkSym:
    newLetStmt(expAlias, exp)
  else:
    newProc(name = genSym(nskTemplate, $expAlias), params = [getType(untyped)],
      body = exp, procType = nnkTemplateDef)

template withValue*[T](source: Option[T]; varname, ifExists, ifAbsent: untyped) =
  ## Reads a value from an Option, assigns it to a variable, and calls `ifExists` when it is `some`.
  ## If the value is `none`, it calls `ifAbsent`.
  runnableExamples:
    some("abc").withValue(foo):
      assert foo == "abc"
    do:
      assert false

    var absentCalled: bool
    none(int).withValue(foo):
      assert false
    do:
      absentCalled = true
    assert absentCalled

  block:
    evalOnceAs(local, source)
    if local.isSome:
      template varname(): auto {.inject, used.} = unsafeGet(local)
      ifExists
    else:
      ifAbsent

template withValue*[T](source: Option[T]; varname, ifExists: untyped) =
  ## Reads a value from an Option, assigns it to a variable, and calls `ifExists` when it is `some`.
  runnableExamples:
    some("abc").withValue(foo):
      assert foo == "abc"

    none(int).withValue(foo):
      assert false

  source.withValue(varname, ifExists):
    discard

template mapIt*[T](value: Option[T], action: untyped): untyped =
  ## Applies an action to the value of the `Option`, if it has one.
  runnableExamples:
    assert some(42).mapIt(it * 2).mapIt($it) == some("84")
    assert none(int).mapIt(it * 2).mapIt($it) == none(string)

  block:
    type InnerType = typeof(
      block:
        var it {.inject, used.}: typeof(value.get())
        action
    )

    var outcome: Option[InnerType]
    value.withValue(it):
      outcome = some(action)
    outcome

template flatMapIt*[T](value: Option[T], action: untyped): untyped =
  ## Executes an action on the value of the `Option`, where that action can also return an `Option`.
  runnableExamples:
    assert some(42).flatMapIt(some($it)) == some("42")
    assert some(42).flatMapIt(none(string)) == none(string)
    assert none(int).flatMapIt(some($it)) == none(string)
    assert none(int).flatMapIt(none(string)) == none(string)

  block:
    type InnerType = typeof(
      block:
        var it {.inject, used.}: typeof(value.get())
        action.get()
    )

    var outcome: Option[InnerType]
    value.withValue(it):
      outcome = action
    outcome

template filterIt*[T](value: Option[T], action: untyped): Option[T] =
  ## Tests the value of the `Option` with a predicate, returning a `none` if it fails.
  runnableExamples:
    assert some(42).filterIt(it > 0) == some(42)
    assert none(int).filterIt(it > 0) == none(int)
    assert some(-11).filterIt(it > 0) == none(int)

  block:
    var outcome = value
    outcome.withValue(it):
      if not action:
        outcome = none(T)
    do:
      outcome = none(T)
    outcome

template applyIt*[T](value: Option[T], action: untyped) =
  ## Executes a code block if the `Option` is `some`, assigning the value to a variable named `it`
  runnableExamples:
    var value: string
    some("foo").applyIt:
      value = it
    assert value == "foo"

    none(string).applyIt:
      assert false

  value.withValue(it):
    action

template `or`*[T](a, b: Option[T]): Option[T] =
  ## Returns the value of the `Option` if it has one, otherwise returns the other `Option`.
  runnableExamples:
    assert((some(42) or some(9999)) == some(42))
    assert((none(int) or some(9999)) == some(9999))
    assert((none(int) or none(int)) == none(int))
  block:
    evalOnceAs(local, a)
    if local.isSome:
      local
    else:
      b
