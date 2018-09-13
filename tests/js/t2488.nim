proc test(): int =
    var i {.global.} = 0
    result = i
    inc i

for i in 0..3:
  doAssert test() == i
