type
  GenericsType[T] = object
  GenericsType2[T] = object
    x: T
  GenericsType3[T, U] = object
    x: T
    y: U
  GenericsType4[T: int or bool] = distinct int
  GenericsType5[N: static[int]; T] = object
    x: array[N, T]
  GenericsType6[T: SomeNumber] = object
    x: T

var genericsType: GenericsType[int]
var genericsType2: GenericsType2[int]
var genericsType3: GenericsType3[float, string]
var genericsType4: GenericsType4[bool]
var genericsType5: GenericsType5[3, float]
var genericsType6: GenericsType6[int8]

proc genericsProc[T]() = discard
genericsProc[int]()

proc genericsProc2[T](x: T) = discard x
genericsProc2(123)

proc genericsProc3[T, U](x: T; y: U) = discard x
genericsProc3("foo", true)

proc genericsProc4[T: int or float](x: T): T = x
discard genericsProc4(1.23)

proc genericsProc5(x: static[int]) = discard x
genericsProc5(123)

proc genericsProc6[T: SomeNumber](x: T) = discard x
genericsProc6(321)

proc genericsProc7[T: SomeNumber](x: T): T = x
discard genericsProc7(321)

proc genericsProc8[N: static[int]; T](x: array[N, T]): T = x[0]
discard genericsProc8([1, 2, 3])
