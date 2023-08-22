#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Saturated arithmetic routines. XXX Make part of the stdlib?

proc `|+|`*(a, b: BiggestInt): BiggestInt =
  ## saturated addition.
  result = a +% b
  if (result xor a) >= 0'i64 or (result xor b) >= 0'i64:
    return result
  if a < 0 or b < 0:
    result = low(typeof(result))
  else:
    result = high(typeof(result))

proc `|-|`*(a, b: BiggestInt): BiggestInt =
  result = a -% b
  if (result xor a) >= 0'i64 or (result xor not b) >= 0'i64:
    return result
  if b > 0:
    result = low(typeof(result))
  else:
    result = high(typeof(result))

proc `|abs|`*(a: BiggestInt): BiggestInt =
  if a != low(typeof(a)):
    if a >= 0: result = a
    else: result = -a
  else:
    result = low(typeof(a))

proc `|div|`*(a, b: BiggestInt): BiggestInt =
  # (0..5) div (0..4) == (0..5) div (1..4) == (0 div 4)..(5 div 1)
  if b == 0'i64:
    # make the same as ``div 1``:
    result = a
  elif a == low(typeof(a)) and b == -1'i64:
    result = high(typeof(result))
  else:
    result = a div b

proc `|mod|`*(a, b: BiggestInt): BiggestInt =
  if b == 0'i64:
    result = a
  else:
    result = a mod b

proc `|*|`*(a, b: BiggestInt): BiggestInt =
  var
    resAsFloat, floatProd: float64
  result = a *% b
  floatProd = toBiggestFloat(a) # conversion
  floatProd = floatProd * toBiggestFloat(b)
  resAsFloat = toBiggestFloat(result)

  # Fast path for normal case: small multiplicands, and no info
  # is lost in either method.
  if resAsFloat == floatProd: return result

  # Somebody somewhere lost info. Close enough, or way off? Note
  # that a != 0 and b != 0 (else resAsFloat == floatProd == 0).
  # The difference either is or isn't significant compared to the
  # true value (of which floatProd is a good approximation).

  # abs(diff)/abs(prod) <= 1/32 iff
  #   32 * abs(diff) <= abs(prod) -- 5 good bits is "close enough"
  if 32.0 * abs(resAsFloat - floatProd) <= abs(floatProd):
    return result

  if floatProd >= 0.0:
    result = high(typeof(result))
  else:
    result = low(typeof(result))
