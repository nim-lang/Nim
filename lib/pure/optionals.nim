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
## For more advanced funcionality see `optutils module <optutils.html>`_.
##
##
## Basic usage
## ===========
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
##    let found = "abc".find('c')
##    assert found.isSome and found.get() == 2
##
## The `get` operation demonstrated above returns the underlying value, or
## raises `UnpackError` if there is no value. Note that `UnpackError`
## inherits from `system.Defect`, and should therefore never be caught.
## Instead, rely on checking if the option contains a value with
## `isSome <#isSome,Option[T]>`_ and `isNone <#isNone,Option[T]>`_ procs.
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

  UnpackError* = object of Defect


proc option*[T](val: T): Option[T] =
  ## Can be used to convert a pointer type (`ptr` or `ref`) to an option type.
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

proc some*[T](val: T): Option[T] =
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
    assert $type(a) == "Option[system.string]"
    assert b.isSome
    assert a.get == "abc"
    assert $b == "Some(42)"

  when T is SomePointer:
    assert(not val.isNil)
    result.val = val
  else:
    result.has = true
    result.val = val

proc none*(T: typedesc): Option[T] =
  ## Returns an `Option` for this type that has no value.
  ##
  ## See also:
  ## * `option <#option,T>`_
  ## * `some <#some,T>`_
  ## * `isNone <#isNone,Option[T]>`_
  runnableExamples:
    var a = none(int)
    assert a.isNone
    assert $type(a) == "Option[system.int]"

  # the default is the none type
  discard

proc none*[T]: Option[T] =
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

proc get*[T](self: Option[T]): T =
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
    doAssertRaises(UnpackError):
      echo b.get

  if self.isNone:
    raise newException(UnpackError, "Can't obtain a value from a `none`")
  self.val

proc get*[T](self: Option[T], otherwise: T): T =
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

proc get*[T](self: var Option[T]): var T =
  ## Returns contents of the `var Option`. If it is `None`, then an exception
  ## is thrown.
  runnableExamples:
    let
      a = some(42)
      b = none(string)
    assert a.get == 42
    doAssertRaises(UnpackError):
      echo b.get

  if self.isNone:
    raise newException(UnpackError, "Can't obtain a value from a `none`")
  return self.val

proc `==`*(a, b: Option): bool =
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

proc unsafeGet*[T](self: Option[T]): T =
  ## Returns the value of a `some`. Behavior is undefined for `none`.
  ##
  ## **Note:** Use it only when you are **absolutely sure** the value is present
  ## (e.g. after checking `isSome <#isSome,Option[T]>`_).
  ## Generally, using `get proc <#get,Option[T]>`_ is preferred.
  assert self.isSome
  self.val


when isMainModule:
  import unittest, sequtils

  # RefPerson is used to test that overloaded `==` operator is not called by
  # options. It is defined here in the global scope, because otherwise the test
  # will not even consider the `==` operator. Different bug?
  type RefPerson = ref object
    name: string

  proc `==`(a, b: RefPerson): bool =
    assert(not a.isNil and not b.isNil)
    a.name == b.name

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
      check($(some("Correct")) == "Some(\"Correct\")")
      check($(stringNone) == "None[string]")

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

    test "$ on typed with .name":
      type Named = object
        name: string

      let nobody = none(Named)
      check($nobody == "None[Named]")

    test "$ on type with name()":
      type Person = object
        myname: string

      let noperson = none(Person)
      check($noperson == "None[Person]")

    test "Ref type with overloaded `==`":
      let p = some(RefPerson.new())
      check p.isSome
