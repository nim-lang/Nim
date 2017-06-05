var a = @[1, 2, 3]
let b = a
a &= @[]
assert a == @[1, 2, 3]
assert b == a
a &= @[4, 5]
assert a == @[1, 2, 3, 4, 5]
