# static types that depend on a generic parameter

block: # issue #19365
  var ss: seq[string]
  proc f[T](x: static T) =
    ss.add($x & ": " & $T)

  f(123)
  doAssert ss == @["123: int"]
  f("abc")
  doAssert ss == @["123: int", "abc: string"]

block: # issue #7209
  type Modulo[A; M: static[A]] = distinct A

  proc `$`[A; M: static[A]](x: Modulo[A, M]): string =
    $(A(x)) & " mod " & $(M)

  proc modulo[A](a: A, M: static[A]): Modulo[A, M] = Modulo[A, M](a %% M)

  proc `+`[A; M: static[A]](x, y: Modulo[A, M]): Modulo[A, M] =
    (A(x) + A(y)).modulo(M)

  doAssert $(3.modulo(7) + 5.modulo(7)) == "1 mod 7"
