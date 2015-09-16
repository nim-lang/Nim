
import tables

type
  UUIDObject* = ref object
    uuid: string

  Registry*[T] = ref object
    objects: Table[string, T]

proc newRegistry*[T](): Registry[T] =
  result = Registry[T]()
  result.objects = initTable[string, T](128)

proc register*[T](self: Registry[T], obj: T) =
  self.objects[obj.uuid] = obj

