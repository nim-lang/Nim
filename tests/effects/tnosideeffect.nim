block: # `.noSideEffect`
  func foo(bar: proc(): int): int = bar()
  var count = 0
  proc fn1(): int = 1
  proc fn2(): int = (count.inc; count)

  template accept(body) =
    doAssert compiles(block:
      body)

  template reject(body) =
    doAssert not compiles(block:
      body)

  accept:
    func fun1() = discard foo(fn1)
  reject:
    func fun1() = discard foo(fn2)

  var foo2: type(foo) = foo
  accept:
    func main() = discard foo(fn1)
  reject:
    func main() = discard foo2(fn1)
