type TFoo{.exportc.} = object
 x:int

var s{.exportc.}: seq[TFoo] = @[]

s.add TFoo(x: 42)

echo s[0].x
