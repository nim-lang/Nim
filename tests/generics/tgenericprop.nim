
type
  TProperty[T] = object of RootObj
    getProc: proc(property: TProperty[T]): T {.nimcall.}
    setProc: proc(property: TProperty[T], value: T) {.nimcall.}
    value: T

proc newProperty[T](value: RootObj): TProperty[T] =
  result.getProc = proc (property: TProperty[T]) =
    return property.value


