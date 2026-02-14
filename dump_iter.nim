import macros

proc iter(v: sink string): iterator(): int =
  iterator(): int =
    yield 1
    echo v

dumpTree:
  let x = iter("test")
  for i in x():
    echo i
