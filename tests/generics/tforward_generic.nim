discard """
  output: '''b()
720 120.0'''
"""

# bug #3055
proc b(t: int | string)
proc a(t: int) = b(t)
proc b(t: int | string) = echo "b()"
a(1)

# test recursive generics still work:
proc fac[T](x: T): T =
  if x == 0: return 1
  else: return fac(x-1)*x

echo fac(6), " ", fac(5.0)

when false:
  # This still doesn't work...
  # test recursive generic with forwarding:
  proc fac2[T](x: T): T

  echo fac2(6), " ", fac2(5.0)

  proc fac2[T](x: T): T =
    if x == 0: return 1
    else: return fac2(x-1)*x
