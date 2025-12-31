discard """
  output: '''
int | int
int | string
int | string
'''
"""

# issue #19517

type thing [T] = object
  value: T

converter asValue[T](o: thing[T]): T =
  o.value

proc mycall(num, num2: int) =
  echo ($(num.type) & " | " & $(num2.type))

proc mycall(num: int, str: string) =
  echo ($(num.type) & " | " & $(str.type))

mycall( # This call uses asValue[int] converter automatically fine
  thing[int](value: 1),
  thing[int](value: 42),
)

mycall( # This gives a type error as if the converter was not defined and I tried to pass in a thing directly
  thing[int](value: 2),
  thing[string](value: "foo"),
)

mycall( # This can be fixed by calling the converter explicitly for everything but the first use
  thing[int](value: 2),
  thing[string](value: "foo").asValue,
)
