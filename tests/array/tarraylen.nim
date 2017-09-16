var a: array[0, int]
assert a.len == 0
assert array[0..0, int].len == 1
assert array[0..0, int]([1]).len == 1
assert array[1..1, int].len == 1
assert array[1..1, int]([1]).len == 1
assert array[2, int].len == 2
assert array[2, int]([1, 2]).len == 2
assert array[1..3, int].len == 3
assert array[1..3, int]([1, 2, 3]).len == 3
assert array[0..2, int].len == 3
assert array[0..2, int]([1, 2, 3]).len == 3
assert array[-2 .. -2, int].len == 1
assert([1, 2, 3].len == 3)
assert([42].len == 1)