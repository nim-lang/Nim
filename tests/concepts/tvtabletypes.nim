type
  Enumerable[T] = concept e
    for v in e:
      v is T

  OutputStream = concept var s
    s.write(string)

  IntEnumerable = vtref Enumerable[int]

  MyObject = object
    enumerables: seq[IntEnumerable]
    streams: seq[OutputStream.vtref]

  ConcreteStream = ref object
    fd: int

proc addEnumerable(o: var MyObject, e: IntEnumerable) =
  o.enumerables.add e

proc addStream(o: var MyObject, e: OutputStream.vtref) =
  o.streams.add e

proc write(s: var ConcreteStream, content: string) =
  echo "writing ", content, " to ", s.fd

proc writeToStreams(o: MyObject, content: string) =
  for s in o.streams:
    s.write(content)

var x = MyObject(enumerables: @[], streams: @[])
var arr = new array[10, int]

addEnumerable(x, arr)
x.addStream(ConcreteStream(fd: 10))

x.writeToStreams("example")

