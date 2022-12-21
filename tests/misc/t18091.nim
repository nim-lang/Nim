template test1(a, b, c: SomeInteger|SomeFloat) =
  echo (float a, float b, float c)

template test2(a, b, c: SomeNumber) =
  echo (float a, float b, float c)

test1(1, 2.0, 3'u8) # Works
test2(1, 2.0, 3'u8)
