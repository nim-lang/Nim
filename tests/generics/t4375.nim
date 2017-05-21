# Issue 4375

type
  Data[V] = ref object
    v: V

proc newObj[V](t: typedesc[Data], v: V): Data[V] =
  Data[V](v: v)

let d = Data.newObj(100)
