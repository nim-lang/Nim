# Issue 4375

type
  Data[V] = ref object
    v: V

proc newObj[V](t: typedesc[Data], v: V): Data[V] =
  new(result)
  result.v = v

proc newObjImplicit[V](t: typedesc[Data], v: V): Data[V] =
  Data[V](v: v)

let d1 = Data.newObj(100)
let d2 = Data.newObjImplicit(100)
