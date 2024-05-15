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
    return $error #[tt.Warning
            ^ a new symbol 'error' has been injected during instantiation of g, however 'error' [enumField declared in tmacroinjectedsymwarning.nim(2, 3)] captured at the proc declaration will be used instead; either enable --experimental:genericsOpenSym to use the injected symbol or `bind` this captured symbol explicitly [GenericsIgnoredInjection]]#

  "ok"

discard g(int)
