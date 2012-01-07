
type
  TProperty[T] = object of TObject
    getProc: proc(property: TProperty[T]): T
    setProc: proc(property: TProperty[T], value: T)
    value: T

proc newProperty[T](value: TObject): TProperty[T] =
  result.getProc = proc (property: TProperty[T]) =
    return property.value


