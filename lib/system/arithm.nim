#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


# Only clang has __has_builtin (so far)
#
# TODO: This is emitted at the wrong position so we don't actually have an
#       emit. Could we add this to nimbase.h instead?
{.emit: """#ifndef __has_builtin
  #define __has_builtin(x) 0
#endif""".}

# Builtin compiler functions for improved performance

proc checkFunction(name: string): string =
  "((__has_builtin(__builtin_" & name & "_overflow)) || __GNUC__ >= 5)"

# TODO: This is totally ugly. But we can't reliably detect this from Nim,
# especially with cross-compiling where the user may be using an older compiler
# version. Switching this on/off manually with a define seems weird as well.
when sizeof(clong) == 8:
  const hasAddInt64Overflow = checkFunction("saddl")
  proc addInt64Overflow[T: int64|int](a, b: T, c: var T): bool {.
    importc: "__builtin_saddl_overflow", nodecl, nosideeffect.}

  const hasSubInt64Overflow = checkFunction("ssubl")
  proc subInt64Overflow[T: int64|int](a, b: T, c: var T): bool {.
    importc: "__builtin_ssubl_overflow", nodecl, nosideeffect.}

  const hasMulInt64Overflow = checkFunction("smull")
  proc mulInt64Overflow[T: int64|int](a, b: T, c: var T): bool {.
    importc: "__builtin_smull_overflow", nodecl, nosideeffect.}

elif sizeof(clonglong) == 8:
  const hasAddInt64Overflow = checkFunction("saddll")
  proc addInt64Overflow[T: int64|int](a, b: T, c: var T): bool {.
    importc: "__builtin_saddll_overflow", nodecl, nosideeffect.}

  const hasSubInt64Overflow = checkFunction("ssubll")
  proc subInt64Overflow[T: int64|int](a, b: T, c: var T): bool {.
    importc: "__builtin_ssubll_overflow", nodecl, nosideeffect.}

  const hasMulInt64Overflow = checkFunction("smulll")
  proc mulInt64Overflow[T: int64|int](a, b: T, c: var T): bool {.
    importc: "__builtin_smulll_overflow", nodecl, nosideeffect.}

when sizeof(int) == 8:
  const hasAddIntOverflow = hasAddInt64Overflow
  proc addIntOverflow(a, b: int, c: var int): bool {.inline.} =
    addInt64Overflow(a, b, c)

  const hasSubIntOverflow = hasSubInt64Overflow
  proc subIntOverflow(a, b: int, c: var int): bool {.inline.} =
    subInt64Overflow(a, b, c)

  const hasMulIntOverflow = hasMulInt64Overflow
  proc mulIntOverflow(a, b: int, c: var int): bool {.inline.} =
    mulInt64Overflow(a, b, c)

elif sizeof(int) == 4 and sizeof(cint) == 4:
  const hasAddIntOverflow = checkFunction("sadd")
  proc addIntOverflow(a, b: int, c: var int): bool {.
    importc: "__builtin_sadd_overflow", nodecl, nosideeffect.}

  const hasSubIntOverflow = checkFunction("ssub")
  proc subIntOverflow(a, b: int, c: var int): bool {.
    importc: "__builtin_ssub_overflow", nodecl, nosideeffect.}

  const hasMulIntOverflow = checkFunction("smul")
  proc mulIntOverflow(a, b: int, c: var int): bool {.
    importc: "__builtin_smul_overflow", nodecl, nosideeffect.}


# simple integer arithmetic with overflow checking

proc raiseOverflow {.compilerproc, noinline, noreturn.} =
  # a single proc to reduce code size to a minimum
  sysFatal(OverflowError, "over- or underflow")

proc raiseDivByZero {.compilerproc, noinline, noreturn.} =
  sysFatal(DivByZeroError, "division by zero")

proc addInt64(a, b: int64): int64 {.compilerProc, inline.} =
  {.emit: "#if `hasAddInt64Overflow`".}
  if addInt64Overflow(a, b, result):
    raiseOverflow()
  {.emit: "#else".}
  result = a +% b
  if (result xor a) >= int64(0) or (result xor b) >= int64(0):
    return result
  raiseOverflow()
  {.emit: "#endif".}

proc subInt64(a, b: int64): int64 {.compilerProc, inline.} =
  {.emit: "#if `hasSubInt64Overflow`".}
  if subInt64Overflow(a, b, result):
    raiseOverflow()
  {.emit: "#else".}
  result = a -% b
  if (result xor a) >= int64(0) or (result xor not b) >= int64(0):
    return result
  raiseOverflow()
  {.emit: "#endif".}

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
  {.emit: "#if `hasMulInt64Overflow`".}
  if mulInt64Overflow(a, b, result):
    raiseOverflow()
  {.emit: "#else".}
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
  raiseOverflow()
  {.emit: "#endif".}


proc absInt(a: int): int {.compilerProc, inline.} =
  if a != low(int):
    if a >= 0: return a
    else: return -a
  raiseOverflow()

const
  asmVersion = defined(I386) and (defined(vcc) or defined(wcc) or
               defined(dmc) or defined(gcc) or defined(llvm_gcc))
    # my Version of Borland C++Builder does not have
    # tasm32, which is needed for assembler blocks
    # this is why Borland is not included in the 'when'

when asmVersion and not defined(gcc) and not defined(llvm_gcc):
  # assembler optimized versions for compilers that
  # have an intel syntax assembler:
  proc addInt(a, b: int): int {.compilerProc, asmNoStackFrame.} =
    # a in eax, and b in edx
    asm """
        mov eax, ecx
        add eax, edx
        jno theEnd
        call `raiseOverflow`
      theEnd:
        ret
    """

  proc subInt(a, b: int): int {.compilerProc, asmNoStackFrame.} =
    asm """
        mov eax, ecx
        sub eax, edx
        jno theEnd
        call `raiseOverflow`
      theEnd:
        ret
    """

  proc negInt(a: int): int {.compilerProc, asmNoStackFrame.} =
    asm """
        mov eax, ecx
        neg eax
        jno theEnd
        call `raiseOverflow`
      theEnd:
        ret
    """

  proc divInt(a, b: int): int {.compilerProc, asmNoStackFrame.} =
    asm """
        mov eax, ecx
        mov ecx, edx
        xor edx, edx
        idiv ecx
        jno  theEnd
        call `raiseOverflow`
      theEnd:
        ret
    """

  proc modInt(a, b: int): int {.compilerProc, asmNoStackFrame.} =
    asm """
        mov eax, ecx
        mov ecx, edx
        xor edx, edx
        idiv ecx
        jno theEnd
        call `raiseOverflow`
      theEnd:
        mov eax, edx
        ret
    """

  proc mulInt(a, b: int): int {.compilerProc, asmNoStackFrame.} =
    asm """
        mov eax, ecx
        mov ecx, edx
        xor edx, edx
        imul ecx
        jno theEnd
        call `raiseOverflow`
      theEnd:
        ret
    """

elif false: # asmVersion and (defined(gcc) or defined(llvm_gcc)):
  proc addInt(a, b: int): int {.compilerProc, inline.} =
    # don't use a pure proc here!
    asm """
      "addl %%ecx, %%eax\n"
      "jno 1\n"
      "call _raiseOverflow\n"
      "1: \n"
      :"=a"(`result`)
      :"a"(`a`), "c"(`b`)
    """
    #".intel_syntax noprefix"
    #/* Intel syntax here */
    #".att_syntax"

  proc subInt(a, b: int): int {.compilerProc, inline.} =
    asm """ "subl %%ecx,%%eax\n"
            "jno 1\n"
            "call _raiseOverflow\n"
            "1: \n"
           :"=a"(`result`)
           :"a"(`a`), "c"(`b`)
    """

  proc mulInt(a, b: int): int {.compilerProc, inline.} =
    asm """  "xorl %%edx, %%edx\n"
             "imull %%ecx\n"
             "jno 1\n"
             "call _raiseOverflow\n"
             "1: \n"
            :"=a"(`result`)
            :"a"(`a`), "c"(`b`)
            :"%edx"
    """

  proc negInt(a: int): int {.compilerProc, inline.} =
    asm """ "negl %%eax\n"
            "jno 1\n"
            "call _raiseOverflow\n"
            "1: \n"
           :"=a"(`result`)
           :"a"(`a`)
    """

  proc divInt(a, b: int): int {.compilerProc, inline.} =
    asm """  "xorl %%edx, %%edx\n"
             "idivl %%ecx\n"
             "jno 1\n"
             "call _raiseOverflow\n"
             "1: \n"
            :"=a"(`result`)
            :"a"(`a`), "c"(`b`)
            :"%edx"
    """

  proc modInt(a, b: int): int {.compilerProc, inline.} =
    asm """  "xorl %%edx, %%edx\n"
             "idivl %%ecx\n"
             "jno 1\n"
             "call _raiseOverflow\n"
             "1: \n"
             "movl %%edx, %%eax"
            :"=a"(`result`)
            :"a"(`a`), "c"(`b`)
            :"%edx"
    """

# Platform independent versions of the above (slower!)
when not declared(addInt):
  proc addInt(a, b: int): int {.compilerProc, inline.} =
    {.emit: "#if `hasAddIntOverflow`".}
    if addIntOverflow(a, b, result):
      raiseOverflow()
    {.emit: "#else".}
    result = a +% b
    if (result xor a) >= 0 or (result xor b) >= 0:
      return result
    raiseOverflow()
    {.emit: "#endif".}

when not declared(subInt):
  proc subInt(a, b: int): int {.compilerProc, inline.} =
    {.emit: "#if `hasSubIntOverflow`".}
    if subIntOverflow(a, b, result):
      raiseOverflow()
    {.emit: "#else".}
    result = a -% b
    if (result xor a) >= 0 or (result xor not b) >= 0:
      return result
    raiseOverflow()
    {.emit: "#endif".}

when not declared(negInt):
  proc negInt(a: int): int {.compilerProc, inline.} =
    if a != low(int): return -a
    raiseOverflow()

when not declared(divInt):
  proc divInt(a, b: int): int {.compilerProc, inline.} =
    if b == 0:
      raiseDivByZero()
    if a == low(int) and b == -1:
      raiseOverflow()
    return a div b

when not declared(modInt):
  proc modInt(a, b: int): int {.compilerProc, inline.} =
    if b == 0:
      raiseDivByZero()
    return a mod b

when not declared(mulInt):
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
  proc mulInt(a, b: int): int {.compilerProc.} =
    {.emit: "#if `hasMulIntOverflow`".}
    if mulIntOverflow(a, b, result):
      raiseOverflow()
    {.emit: "#else".}
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
    {.emit: "#endif".}

# We avoid setting the FPU control word here for compatibility with libraries
# written in other languages.

proc raiseFloatInvalidOp {.noinline, noreturn.} =
  sysFatal(FloatInvalidOpError, "FPU operation caused a NaN result")

proc nanCheck(x: float64) {.compilerProc, inline.} =
  if x != x: raiseFloatInvalidOp()

proc raiseFloatOverflow(x: float64) {.noinline, noreturn.} =
  if x > 0.0:
    sysFatal(FloatOverflowError, "FPU operation caused an overflow")
  else:
    sysFatal(FloatUnderflowError, "FPU operations caused an underflow")

proc infCheck(x: float64) {.compilerProc, inline.} =
  if x != 0.0 and x*0.5 == x: raiseFloatOverflow(x)
