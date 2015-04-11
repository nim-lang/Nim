#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## :Author: Oleh Prypin
##
## Abstract
## ========
##
## This module implements types which encapsulate an optional value.
##
## A value of type ``?T`` (``Maybe[T]``) either contains a value `x`
## (represented as ``just(x)``) or is empty (``nothing[T]``).
##
## This can be useful when you have a value that can be present or not.
## The absence of a value is often represented by ``nil``, but it is not always
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
##   proc find(haystack: string, needle: char): ?int =
##     for i, c in haystack:
##       if c == needle:
##         return just i
##     return nothing[int]  # This line is actually optional,
##                          # because the default is empty
##
##   try:
##     assert("abc".find('c')[] == 2)  # Immediately extract the value
##   except FieldError:  # If there is no value
##     assert false  # This will not be reached, because the value is present
##
##
## How to deal with an absence of a value:
##
## .. code-block:: nim
##
##   let result = "team".find('i')
##
##   # Nothing was found, so the result is `nothing`.
##   assert(result == nothing[int])
##   # It has no value:
##   assert(result.has == false)
##   # A different way to write it:
##   assert(not result)
##
##   try:
##     echo result[]
##     assert(false)  # This will not be reached
##   except FieldError:  # Because an exception is raised
##     discard
##
## Now let's try out the extraction template. It returns whether a value
## is present and injects the value into a variable. It is meant to be used in
## a conditional.
##
## .. code-block:: nim
##
##   if pos ?= "nim".find('i'):
##     assert(pos is int)  # This is a normal integer, no tricks.
##     echo "Match found at position ", pos
##   else:
##     assert(false)  # This will not be reached
##
## Or maybe you want to get the behavior of the standard library's ``find``,
## which returns `-1` if nothing was found.
##
## .. code-block:: nim
##
##   assert(("team".find('i') or -1) == -1)
##   assert(("nim".find('i') or -1) == 1)
##
##
## API Details
## ===========
##
## There are two different implementations of ``Maybe`` in this module.
## Usually you shouldn't concern yourself with this. The ``?`` template returns
## the appropriate type.
##
## - ``MaybeObj`` works for all types. It's an object that contains a ``bool``
##   and the value.
## - ``MaybeDistinct`` relies on the value being nil or non-nil (so you can't
##   store actual nil values in it). This doesn't necessarily mean equality or
##   inequality to ``nil``. This ``Maybe`` type is chosen for all objects that
##   have ``isNil`` defined. It also has the requirement that the default state
##   of the type without any initialization (i.e. all zeros) is the ``isNil``
##   state. If you can't or don't want to ensure this, you must pass the
##   nil-state value to ``nothing()``. See an example under ``()``.


type
  Nullable = concept x
    isNil(x) is bool

  MaybeDistinct*[T] = distinct T
    ## A ``Maybe`` type that is `nothing` when the underlying object ``isNil``

  MaybeObj*[T] = object
    ## A ``Maybe`` type that stores its value and state separately in a boolean
    val: T
    has: bool

  Maybe*[T] = MaybeDistinct[T] or MaybeObj[T]


template `?`*(T: typedesc): typedesc =
  ## Returns ``MaybeDistinct[T]`` for types that have ``isNil`` defined
  ## and ``MaybeObj[T]`` for others.
  ##
  ## .. code-block:: nim
  ##
  ##   assert(?string is MaybeDistinct)
  ##   assert(?int is MaybeObj)
  when T is Nullable:
    MaybeDistinct[T]
  else:
    MaybeObj[T]


proc just*[T](val: T): auto =
  ## Returns a `just` of type ``?T`` with the value `val`.
  ##
  ## .. code-block:: nim
  ##
  ##   assert type(just 5) is ?int
  ##   assert just(5).has

  when T is Nullable:
    if isNil(val):
      raise newException(ValueError, "Can't create a `just` from nil")
    MaybeDistinct[T](val)
  else:
    MaybeObj[T](has: true, val: val)



type Nothing = object
const nothing* = Nothing()
  ## Placeholder to allow the syntax ``nothing[]`` and ``nothing()``.

proc `[]`*(nothing: type(nothing), T: typedesc): auto =
  ## Returns a `nothing` of type ``?T``.
  ##
  ## If `T` has ``isNil`` defined, its default state must be such that
  ## ``isNil`` is ``true``. Otherwise, use ``nothing(val)``.
  ##
  ## .. code-block:: nim
  ##
  ##   assert type(nothing[string]) is ?string
  ##   assert nothing[string].has == false
  when T is Nullable:
    var val: T
    if not isNil(val):
      raise newException(ValueError, "The type's default state must be nil")
    MaybeDistinct[T](val)
  else:
    MaybeObj[T]()

proc `()`*[T](nothing: type(nothing), val: T): auto =
  ## Returns a `nothing` of type ``?T``.
  ##
  ## ``isNil(val)`` must be ``true``.
  ##
  ## .. code-block:: nim
  ##
  ##   proc isNil(s: Slice[int]): bool =
  ##     s.a == int.low and s.b == int.low
  ##
  ##   assert type(?Slice[int]) is MaybeDistinct
  ##   assert nothing(int.low..int.low).has == false
  if not isNil(val):
    raise newException(ValueError, "Can't create a `nothing` from non-nil")
  when val is Nullable:
    MaybeDistinct[T](val)
  else:
    MaybeObj[T](val: val)


proc has*[T](opt: Maybe[T]): bool =
  ## Returns ``true`` if `opt` isn't `nothing`.
  when opt is MaybeDistinct:
    not isNil(T(opt))
  else:
    opt.has

converter toBool*(opt: Maybe): bool =
  ## Same as ``has``. Allows to use a ``Maybe`` in boolean context.
  opt.has


proc val*[T](opt: Maybe[T]): T =
  ## Unsafe. Returns the value of a `just`. Behavior is undefined for `nothing`.
  when opt is MaybeDistinct:
    T(opt)
  else:
    opt.val


proc `[]`*[T](opt: Maybe[T]): T =
  ## Returns the value of `opt`. Raises ``FieldError`` if it is `nothing`.
  if not opt:
    raise newException(FieldError, "Can't obtain a value from a `nothing`")
  opt.val

proc `or`*[T](opt: Maybe[T], default: T): T =
  ## Returns the value of `opt`, or `default` if it is `nothing`.
  if opt: opt.val
  else: default

proc `or`*[T](a, b: Maybe[T]): Maybe[T] =
  ## Returns `a` if it is `just`, otherwise `b`.
  if a: a
  else: b


proc `==`*[T](a, b: Maybe[T]): bool =
  (a.has and b.has and a.val == b.val) or (not a.has and not b.has)

template `?=`*(into: expr, opt: Maybe): bool =
  ## Returns ``true`` if `opt` isn't `nothing`.
  ##
  ## Injects a variable with the name specified by the argument `into`
  ## with the value of `opt`, or its type's default value if it is `nothing`
  ##
  ## .. code-block:: nim
  ##   proc message(): ?string =
  ##     just "Hello"
  ##
  ##   if m ?= message():
  ##     echo m
  var into {.inject.}: type(opt.val)
  if opt:
    into = opt.val
  opt



when isMainModule:
  import typetraits

  template expect(E: expr, body: stmt): stmt {.immediate.} =
    try:
      body
      assert false, "Exception not raised"
    except E:
      discard


  proc find(haystack: string, needle: char): ?int =
    for i, c in haystack:
      if c == needle:
        return just i

  assert("abc".find('c')[] == 2)


  let result = "team".find('i')

  assert result == nothing[int]
  assert result.has == false

  expect FieldError:
    echo result[]


  if pos ?= "nim".find('i'):
    assert pos is int
    assert pos == 1
  else:
    assert false


  assert(("team".find('i') or -1) == -1)
  assert(("nim".find('i') or -1) == 1)


  assert(?string is MaybeDistinct)
  assert(?int is MaybeObj)


  assert type(just 5) is ?int
  assert just(5).has


  assert type(nothing[string]) is ?string
  assert nothing[string].has == false


  proc isNil(s: Slice[int]): bool =
    s.a == int.low and s.b == int.low

  assert type(?Slice[int]) is MaybeDistinct
  assert nothing(int.low..int.low).has == false


  var nilstr: string
  assert nothing[string] == nothing(nilstr)
  assert just("abc") == just("abc")

  assert nothing[int] == nothing[int]
  assert just(7) == just(7)

  expect ValueError:
    discard just(nilstr)
  expect ValueError:
    discard just(int.low..int.low)

  expect ValueError:
    discard nothing("a")
  expect ValueError:
    discard nothing(int.low..6)
  expect ValueError:
    discard nothing[Slice[int]]
