block: # issue #22605, normal call syntax
  const error = "bad"

  template valueOr(self: int, def: untyped): untyped =
    case false
    of true: ""
    of false:
      template error: untyped {.used, inject.} = "good"
      def

  proc g(T: type): string =
    let x = valueOr 123:
      return $error

    "ok"

  doAssert g(int) == "good"

block: # issu #22605, method call syntax
  const error = "bad"

  template valueOr(self: int, def: untyped): untyped =
    case false
    of true: ""
    of false:
      template error: untyped {.used, inject.} = "good"
      def

  proc g(T: type): string =
    let x = 123.valueOr:
      return $error

    "ok"

  doAssert g(int) == "good"

block: # issue #22605, template case
  template valueOr(self, def: untyped): untyped =
    block:
      template error: untyped {.used, inject.} = "good"
      def

  const error = "bad"
  template g: untyped =
    let x = 123.valueOr:
      $error
    x
  doAssert g == "good"

block: # issue #22605, original complex example
  type Xxx = enum
    error
    value

  type
    Result[T, E] = object
      when T is void:
        when E is void:
          oResultPrivate*: bool
        else:
          case oResultPrivate*: bool
          of false:
            eResultPrivate*: E
          of true:
            discard
      else:
        when E is void:
          case oResultPrivate*: bool
          of false:
            discard
          of true:
            vResultPrivate*: T
        else:
          case oResultPrivate*: bool
          of false:
            eResultPrivate*: E
          of true:
            vResultPrivate*: T

  template valueOr[T: not void, E](self: Result[T, E], def: untyped): untyped =
    let s = (self) # TODO avoid copy
    case s.oResultPrivate
    of true:
      s.vResultPrivate
    of false:
      when E isnot void:
        template error: untyped {.used, inject.} = s.eResultPrivate
      def

  proc f(): Result[int, cstring] =
    Result[int, cstring](oResultPrivate: false, eResultPrivate: "f")

  proc g(T: type): string =
    let x = f().valueOr:
      return $error

    "ok"

  doAssert g(int) == "f"

# issue #11184

import mopensym

type
  MyType = object

proc foo0(arg: MyType): string =
  "foo0"

proc foo1(arg: MyType): string =
  "foo1"

proc foo2(arg: MyType): string =
  "foo2"

proc test() =
  var bar: MyType

  doAssert myTemplate0() == "foo0"
  doAssert myTemplate1() == "foo1"
  doAssert myTemplate2() == "foo2"

test()
