proc getState*(): int =
  var state0 {.global.}: int
  inc state0
  result = state0

for i in 0 ..< 3:
  doAssert getState() == i + 1

for i in 0 ..< 3:
  once:
    doAssert i == 0
