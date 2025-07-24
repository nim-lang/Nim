import macros

type float32x4 = array[4, float32]
type float32x8 = array[8, float32]

{.experimental: "dynamicBindSym".}
macro dispatch(N: static int, T: type SomeNumber): untyped =
  let BaseT = getTypeInst(T)[1]
  result = bindSym($BaseT & "x" & $N)

type
  VecIntrin*[N: static int, T: SomeNumber] = dispatch(N, T)

func `$`*[N, T](vec: VecIntrin[N, T]): string =
  ## Display a vector
  $cast[array[N, T]](vec)
