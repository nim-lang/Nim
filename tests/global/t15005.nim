type
  T = ref object
    data: string

template foo(): T =
  var a15005 {.global.}: T
  once:
    a15005 = T(data: "hi")

  a15005

proc test() =
  var b15005 = foo()

  doAssert b15005.data == "hi"

test()
test()
