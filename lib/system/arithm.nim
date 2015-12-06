#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


# simple integer arithmetic with overflow checking

proc raiseOverflow {.compilerproc, noinline.} =
  # a single proc to reduce code size to a minimum
  sysFatal(OverflowError, "over- or underflow")

proc raiseDivByZero {.compilerproc, noinline.} =
  sysFatal(DivByZeroError, "division by zero")

when defined(builtinOverflow):
  # Builtin compiler functions for improved performance
  when sizeof(clong) == 8:
    proc addInt64Overflow[T: int64|int](a, b: T, c: var T): bool {.
      importc: "__builtin_saddl_overflow", nodecl, nosideeffect.}

    proc subInt64Overflow[T: int64|int](a, b: T, c: var T): bool {.
      importc: "__builtin_ssubl_overflow", nodecl, nosideeffect.}

    proc mulInt64Overflow[T: int64|int](a, b: T, c: var T): bool {.
      importc: "__builtin_smull_overflow", nodecl, nosideeffect.}

  elif sizeof(clonglong) == 8:
    proc addInt64Overflow[T: int64|int](a, b: T, c: var T): bool {.
      importc: "__builtin_saddll_overflow", nodecl, nosideeffect.}

    proc subInt64Overflow[T: int64|int](a, b: T, c: var T): bool {.
      importc: "__builtin_ssubll_overflow", nodecl, nosideeffect.}

    proc mulInt64Overflow[T: int64|int](a, b: T, c: var T): bool {.
      importc: "__builtin_smulll_overflow", nodecl, nosideeffect.}

  when sizeof(int) == 8:
    proc addIntOverflow(a, b: int, c: var int): bool {.inline.} =
      addInt64Overflow(a, b, c)

    proc subIntOverflow(a, b: int, c: var int): bool {.inline.} =
      subInt64Overflow(a, b, c)

    proc mulIntOverflow(a, b: int, c: var int): bool {.inline.} =
      mulInt64Overflow(a, b, c)

  elif sizeof(int) == 4 and sizeof(cint) == 4:
    proc addIntOverflow(a, b: int, c: var int): bool {.
      importc: "__builtin_sadd_overflow", nodecl, nosideeffect.}

    proc subIntOverflow(a, b: int, c: var int): bool {.
      importc: "__builtin_ssub_overflow", nodecl, nosideeffect.}

    proc mulIntOverflow(a, b: int, c: var int): bool {.
      importc: "__builtin_smul_overflow", nodecl, nosideeffect.}

  proc addInt64(a, b: int64): int64 {.compilerProc, inline.} =
    if addInt64Overflow(a, b, result):
      raiseOverflow()

  proc subInt64(a, b: int64): int64 {.compilerProc, inline.} =
    if subInt64Overflow(a, b, result):
      raiseOverflow()

  proc mulInt64(a, b: int64): int64 {.compilerproc, inline.} =
    if mulInt64Overflow(a, b, result):
      raiseOverflow()
else:
  proc addInt64(a, b: int64): int64 {.compilerProc, inline.} =
    result = a +% b
    if (result xor a) >= int64(0) or (result xor b) >= int64(0):
      return result
    raiseOverflow()

  proc subInt64(a, b: int64): int64 {.compilerProc, inline.} =
    result = a -% b
    if (result xor a) >= int64(0) or (result xor not b) >= int64(0):
      return result
    raiseOverflow()

  proc mulInt64(a, b: int64): int64 {.compilerproc.} =
    # This version of abs does not fail on x == low(int),
    # but may return a negative value in this case.
    # Hence all arithmetic using the result must be unsigned.
    template safe_abs(x: int64): int64 =
      let tmp = int64(x < 0)
      (x xor -tmp) +% tmp
    result = a *% b
    let a_abs = safe_abs(a)
    let b_abs = safe_abs(b)
    # Fast path if we can quickly prove that the arguments
    # are less than sqrt(high(int64)); the actual bound is even
    # a bit lower.
    if (a_abs or b_abs) <% (1 shl (sizeof(int64) * 4 - 1)):
      return
    # General overflow check; this employs the equivalence
    # a * b < c iff a < c / b for b != 0
    if b == 0 or a_abs <=% high(int64) /% b_abs:
      return
    # Special case for result == low(int64)
    if a == 1 or b == 1:
      return
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

when not declared(addInt) and defined(builtinOverflow):
  proc addInt(a, b: int): int {.compilerProc, inline.} =
    if addIntOverflow(a, b, result):
      raiseOverflow()

when not declared(subInt) and defined(builtinOverflow):
  proc subInt(a, b: int): int {.compilerProc, inline.} =
    if subIntOverflow(a, b, result):
      raiseOverflow()

when not declared(mulInt) and defined(builtinOverflow):
  proc mulInt(a, b: int): int {.compilerProc, inline.} =
    if mulIntOverflow(a, b, result):
      raiseOverflow()

# Platform independent versions of the above (slower!)
when not declared(addInt):
  proc addInt(a, b: int): int {.compilerProc, inline.} =
    result = a +% b
    if (result xor a) >= 0 or (result xor b) >= 0:
      return result
    raiseOverflow()

when not declared(subInt):
  proc subInt(a, b: int): int {.compilerProc, inline.} =
    result = a -% b
    if (result xor a) >= 0 or (result xor not b) >= 0:
      return result
    raiseOverflow()

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
  proc mulInt(a, b: int): int {.compilerProc.} =
    # This version of abs does not fail on x == low(int),
    # but may return a negative value in this case.
    # Hence all arithmetic using the result must be unsigned.
    template safe_abs(x: int): int =
      let tmp = int(x < 0)
      (x xor -tmp) +% tmp
    result = a *% b
    let a_abs = safe_abs(a)
    let b_abs = safe_abs(b)
    # Fast path if we can quickly prove that the arguments
    # are less than sqrt(high(int)); the actual bound is even
    # a bit lower.
    if (a_abs or b_abs) <% (1 shl (sizeof(int) * 4 - 1)):
      return
    # General overflow check; this employs the equivalence
    # a * b < c iff a < c / b for b != 0
    if b == 0 or a_abs <=% high(int) /% b_abs:
      return
    # Special case for result == low(int)
    if b == 1 or a == 1:
      return
    raiseOverflow()

# We avoid setting the FPU control word here for compatibility with libraries
# written in other languages.

proc raiseFloatInvalidOp {.noinline.} =
  sysFatal(FloatInvalidOpError, "FPU operation caused a NaN result")

proc nanCheck(x: float64) {.compilerProc, inline.} =
  if x != x: raiseFloatInvalidOp()

proc raiseFloatOverflow(x: float64) {.noinline.} =
  if x > 0.0:
    sysFatal(FloatOverflowError, "FPU operation caused an overflow")
  else:
    sysFatal(FloatUnderflowError, "FPU operations caused an underflow")

proc infCheck(x: float64) {.compilerProc, inline.} =
  if x != 0.0 and x*0.5 == x: raiseFloatOverflow(x)
