# bug #4089

type
  Proc = proc(args: openArray[Bar]): Bar

  Foo = object
    p: Proc

  Bar = object
    f: Foo

proc bar(val: Foo): Bar = Bar()
