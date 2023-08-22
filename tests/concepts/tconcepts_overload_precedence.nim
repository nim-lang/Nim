discard """
  output: '''x as ParameterizedType[T]
x as ParameterizedType[T]
x as ParameterizedType[T]
x as ParameterizedType
x as ParameterizedType
x as CustomTypeClass'''
"""

type ParameterizedType[T] = object

type CustomTypeClass = concept c
  true

# 3 competing procs
proc a[T](x: ParameterizedType[T]) =
  echo "x as ParameterizedType[T]"

proc a(x: ParameterizedType) =
  echo "x as ParameterizedType"

proc a(x: CustomTypeClass) =
  echo "x as CustomTypeClass"

# the same procs in different order
proc b(x: ParameterizedType) =
  echo "x as ParameterizedType"

proc b(x: CustomTypeClass) =
  echo "x as CustomTypeClass"

proc b[T](x: ParameterizedType[T]) =
  echo "x as ParameterizedType[T]"

# and yet another order
proc c(x: CustomTypeClass) =
  echo "x as CustomTypeClass"

proc c(x: ParameterizedType) =
  echo "x as ParameterizedType"

proc c[T](x: ParameterizedType[T]) =
  echo "x as ParameterizedType[T]"

# remove the most specific one
proc d(x: ParameterizedType) =
  echo "x as ParameterizedType"

proc d(x: CustomTypeClass) =
  echo "x as CustomTypeClass"

# then shuffle the order again
proc e(x: CustomTypeClass) =
  echo "x as CustomTypeClass"

proc e(x: ParameterizedType) =
  echo "x as ParameterizedType"

# the least specific one is a match
proc f(x: CustomTypeClass) =
  echo "x as CustomTypeClass"

a(ParameterizedType[int]())
b(ParameterizedType[int]())
c(ParameterizedType[int]())
d(ParameterizedType[int]())
e(ParameterizedType[int]())
f(ParameterizedType[int]())

