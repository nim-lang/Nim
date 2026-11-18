type Box*[T] = object
  name: string
  val*: T

proc box*[T](v: T): Box[T] = Box[T](name: "box", val: v)
