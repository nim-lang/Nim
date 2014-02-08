
type
  TProperty[T] = object of TObject
    getProc: proc(property: TProperty[T]): T {.nimcall.}
    setProc: proc(property: TProperty[T], value: T) {.nimcall.}
    value: T

proc newProperty[T](value: TObject): TProperty[T] =
  result.getProc = proc (property: TProperty[T]) =
    return property.value


