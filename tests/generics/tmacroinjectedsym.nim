{.experimental: "genericsOpenSym".}

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

  proc g2(T: type): string =
    bind error # use the bad version on purpose
    let x = valueOr 123:
      return $error

    "ok"

  doAssert g2(int) == "bad"

block: # issue #22605, method call syntax
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

  proc g2(T: type): string =
    bind error # use the bad version on purpose
    let x = 123.valueOr:
      return $error

    "ok"

  doAssert g2(int) == "bad"

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

  proc g2(T: type): string =
    bind error # use the bad version on purpose
    let x = f().valueOr:
      return $error

    "ok"

  doAssert g2(int) == "error"
