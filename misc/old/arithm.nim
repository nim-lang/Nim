#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2006 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


# simple integer arithmetic with overflow checking

proc raiseOverflow {.exportc: "raiseOverflow", noinline.} =
  # a single proc to reduce code size to a minimum
  raise newException(EOverflow, "over- or underflow")

proc raiseDivByZero {.exportc: "raiseDivByZero", noinline.} =
  raise newException(EDivByZero, "divison by zero")

template addIntXX(name, typ: expr): stmt =
  proc name(a, b: typ): typ {.compilerproc, inline.} =
    result = a +% b
    if (result xor a) >= typ(0) or (result xor b) >= typ(0):
      return result
    raiseOverflow()

template subIntXX(name, typ: expr): stmt =
  proc name(a, b: typ): typ {.compilerProc, inline.} =
    result = a -% b
    if (result xor a) >= typ(0) or (result xor not b) >= typ(0):
      return result
    raiseOverflow()

addIntXX(addInt8, int8)
addIntXX(addInt16, int16)
addIntXX(addInt32, int32)
addIntXX(addInt64, int64)

subIntXX(subInt8, int8)
subIntXX(subInt16, int16)
subIntXX(subInt32, int32)
#subIntXX(subInt64, int64)

#proc addInt64(a, b: int64): int64 {.compilerProc, inline.} =
#  result = a +% b
#  if (result xor a) >= int64(0) or (result xor b) >= int64(0):
#    return result
#  raiseOverflow()

proc subInt64(a, b: int64): int64 {.compilerProc, inline.} =
  result = a -% b
  if (result xor a) >= int64(0) or (result xor not b) >= int64(0):
    return result
  raiseOverflow()

proc negInt64(a: int64): int64 {.compilerProc, inline.} =
  if a != low(int64): return -a
  raiseOverflow()

proc absInt64(a: int64): int64 {.compilerProc, inline.} =
  if a != low(int64):
    if a >= 0: return a
    else: return -a
  raiseOverflow()

proc divInt64(a, b: int64): int64 {.compilerProc, inline.} =
  if b == int64(0):
    raiseDivByZero()
  if a == low(int64) and b == int64(-1):
    raiseOverflow()
  return a div b

proc modInt64(a, b: int64): int64 {.compilerProc, inline.} =
  if b == int64(0):
    raiseDivByZero()
  return a mod b

#
# This code has been inspired by Python's source code.
# The native int product x*y is either exactly right or *way* off, being
# just the last n bits of the true product, where n is the number of bits
# in an int (the delivered product is the true product plus i*2**n for
# some integer i).
#
# The native float64 product x*y is subject to three
# rounding errors: on a sizeof(int)==8 box, each cast to double can lose
# info, and even on a sizeof(int)==4 box, the multiplication can lose info.
# But, unlike the native int product, it's not in *range* trouble:  even
# if sizeof(int)==32 (256-bit ints), the product easily fits in the
# dynamic range of a float64. So the leading 50 (or so) bits of the float64
# product are correct.
#
# We check these two ways against each other, and declare victory if they're
# approximately the same. Else, because the native int product is the only
# one that can lose catastrophic amounts of information, it's the native int
# product that must have overflowed.
#
proc mulInt64(a, b: int64): int64 {.compilerproc.} =
  var
    resAsFloat, floatProd: float64
  result = a *% b
  floatProd = float64(a) # conversion
  floatProd = floatProd * float64(b)
  resAsFloat = float64(result)

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
  raiseOverflow()


proc absInt(a: int): int {.compilerProc, inline.} =
  if a != low(int):
    if a >= 0: return a
    else: return -a
  raiseOverflow()

const
  asmVersion = defined(I386) and (defined(vcc) or defined(wcc) or defined(dmc))
    # my Version of Borland C++Builder does not have
    # tasm32, which is needed for assembler blocks
    # this is why Borland is not included in the 'when'
  useInline = not asmVersion

when asmVersion and defined(gcc):
  proc addInt(a, b: int): int {.compilerProc, pure, inline.}
  proc subInt(a, b: int): int {.compilerProc, pure, inline.}
  proc mulInt(a, b: int): int {.compilerProc, pure, inline.}
  proc divInt(a, b: int): int {.compilerProc, pure, inline.}
  proc modInt(a, b: int): int {.compilerProc, pure, inline.}
  proc negInt(a: int): int {.compilerProc, pure, inline.}

elif asmVersion:
  proc addInt(a, b: int): int {.compilerProc, pure.}
  proc subInt(a, b: int): int {.compilerProc, pure.}
  proc mulInt(a, b: int): int {.compilerProc, pure.}
  proc divInt(a, b: int): int {.compilerProc, pure.}
  proc modInt(a, b: int): int {.compilerProc, pure.}
  proc negInt(a: int): int {.compilerProc, pure.}

elif useInline:
  proc addInt(a, b: int): int {.compilerProc, inline.}
  proc subInt(a, b: int): int {.compilerProc, inline.}
  proc mulInt(a, b: int): int {.compilerProc.}
      # mulInt is to large for inlining?
  proc divInt(a, b: int): int {.compilerProc, inline.}
  proc modInt(a, b: int): int {.compilerProc, inline.}
  proc negInt(a: int): int {.compilerProc, inline.}

else:
  proc addInt(a, b: int): int {.compilerProc.}
  proc subInt(a, b: int): int {.compilerProc.}
  proc mulInt(a, b: int): int {.compilerProc.}
  proc divInt(a, b: int): int {.compilerProc.}
  proc modInt(a, b: int): int {.compilerProc.}
  proc negInt(a: int): int {.compilerProc.}

# implementation:

when asmVersion and not defined(gcc):
  # assembler optimized versions for compilers that
  # have an intel syntax assembler:
  proc addInt(a, b: int): int =
    # a in eax, and b in edx
    asm """
        mov eax, `a`
        add eax, `b`
        jno theEnd
        call raiseOverflow
      theEnd:
    """

  proc subInt(a, b: int): int =
    asm """
        mov eax, `a`
        sub eax, `b`
        jno theEnd
        call raiseOverflow
      theEnd:
    """

  proc negInt(a: int): int =
    asm """
        mov eax, `a`
        neg eax
        jno theEnd
        call raiseOverflow
      theEnd:
    """

  proc divInt(a, b: int): int =
    asm """
        mov eax, `a`
        mov ecx, `b`
        xor edx, edx
        idiv ecx
        jno  theEnd
        call raiseOverflow
      theEnd:
    """

  proc modInt(a, b: int): int =
    asm """
        mov eax, `a`
        mov ecx, `b`
        xor edx, edx
        idiv ecx
        jno theEnd
        call raiseOverflow
      theEnd:
        mov eax, edx
    """

  proc mulInt(a, b: int): int =
    asm """
        mov eax, `a`
        mov ecx, `b`
        xor edx, edx
        imul ecx
        jno theEnd
        call raiseOverflow
      theEnd:
    """

elif asmVersion and defined(gcc):
  proc addInt(a, b: int): int =
    asm """ "addl %1,%%eax\n"
             "jno 1\n"
             "call _raiseOverflow\n"
             "1: \n"
            :"=a"(`a`)
            :"a"(`a`), "r"(`b`)
    """

  proc subInt(a, b: int): int =
    asm """ "subl %1,%%eax\n"
             "jno 1\n"
             "call _raiseOverflow\n"
             "1: \n"
            :"=a"(`a`)
            :"a"(`a`), "r"(`b`)
    """

  proc negInt(a: int): int =
    asm """  "negl %%eax\n"
             "jno 1\n"
             "call _raiseOverflow\n"
             "1: \n"
            :"=a"(`a`)
            :"a"(`a`)
    """

  proc divInt(a, b: int): int =
    asm """  "xorl %%edx, %%edx\n"
             "idivl %%ecx\n"
             "jno 1\n"
             "call _raiseOverflow\n"
             "1: \n"
             :"=a"(`a`)
             :"a"(`a`), "c"(`b`)
             :"%edx"
    """

  proc modInt(a, b: int): int =
    asm """  "xorl %%edx, %%edx\n"
             "idivl %%ecx\n"
             "jno 1\n"
             "call _raiseOverflow\n"
             "1: \n"
             "movl %%edx, %%eax"
             :"=a"(`a`)
             :"a"(`a`), "c"(`b`)
             :"%edx"
    """

  proc mulInt(a, b: int): int =
    asm """  "xorl %%edx, %%edx\n"
             "imull %%ecx\n"
             "jno 1\n"
             "call _raiseOverflow\n"
             "1: \n"
             :"=a"(`a`)
             :"a"(`a`), "c"(`b`)
             :"%edx"
    """

else:
  # Platform independant versions of the above (slower!)

  proc addInt(a, b: int): int =
    result = a +% b
    if (result xor a) >= 0 or (result xor b) >= 0:
      return result
    raiseOverflow()

  proc subInt(a, b: int): int =
    result = a -% b
    if (result xor a) >= 0 or (result xor not b) >= 0:
      return result
    raiseOverflow()

  proc negInt(a: int): int =
    if a != low(int): return -a
    raiseOverflow()

  proc divInt(a, b: int): int =
    if b == 0:
      raiseDivByZero()
    if a == low(int) and b == -1:
      raiseOverflow()
    return a div b

  proc modInt(a, b: int): int =
    if b == 0:
      raiseDivByZero()
    return a mod b

  #
  # This code has been inspired by Python's source code.
  # The native int product x*y is either exactly right or *way* off, being
  # just the last n bits of the true product, where n is the number of bits
  # in an int (the delivered product is the true product plus i*2**n for
  # some integer i).
  #
  # The native float64 product x*y is subject to three
  # rounding errors: on a sizeof(int)==8 box, each cast to double can lose
  # info, and even on a sizeof(int)==4 box, the multiplication can lose info.
  # But, unlike the native int product, it's not in *range* trouble:  even
  # if sizeof(int)==32 (256-bit ints), the product easily fits in the
  # dynamic range of a float64. So the leading 50 (or so) bits of the float64
  # product are correct.
  #
  # We check these two ways against each other, and declare victory if
  # they're approximately the same. Else, because the native int product is
  # the only one that can lose catastrophic amounts of information, it's the
  # native int product that must have overflowed.
  #
  proc mulInt(a, b: int): int =
    var
      resAsFloat, floatProd: float

    result = a *% b
    floatProd = toFloat(a) * toFloat(b)
    resAsFloat = toFloat(result)

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
    raiseOverflow()
