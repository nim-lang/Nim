import sugar

var s = newSeq[proc (): int](5)
{.push exportc.}
proc bar() =
  for i in 0 ..< s.len:
    let foo = i + 1
    capture foo:
      s[i] = proc(): int = foo
{.pop.}

bar()

for i, p in s.pairs:
  let foo = i + 1
  doAssert p() == foo
