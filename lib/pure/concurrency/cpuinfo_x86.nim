
proc cpuidX86(leaf: int32): tuple[eax, ebx, ecx, edx: int32] =
  when defined(vcc):
    # limited inline asm support in vcc, so intrinsics, here we go:
    proc cpuidVcc(cpuInfo: ptr int32; functionID: int32)
      {.cdecl, importc: "__cpuid", header: "intrin.h".}
    cpuidVcc(addr result.eax, leaf)
  else:
    var (eaxr, ebxr, ecxr, edxr) = (0'i32, 0'i32, 0'i32, 0'i32)
    # zero ecx first!
    asm """
      xorl %%ecx, %%ecx
      cpuid
      :"=a"(`eaxr`), "=b"(`ebxr`), "=c"(`ecxr`), "=d"(`edxr`)
      :"a"(`leaf`) """
    (eaxr, ebxr, ecxr, edxr)

proc cpuNameX86(): string =
  var leaves {.global.} = cast[array[48, char]]([
    cpuidX86(leaf = 0x80000002'i32),
    cpuidX86(leaf = 0x80000003'i32),
    cpuidX86(leaf = 0x80000004'i32)])
  result = $cast[cstring](addr leaves[0])

type
  X86Feature {.pure.} = enum
    HypervisorPresence, Hyperthreading, NoSMT, IntelVtx, Amdv, X87fpu, Mmx,
    MmxExt, F3DNow, F3DNowEnhanced, Prefetch, Sse, Sse2, Sse3, Ssse3, Sse4a,
    Sse41, Sse42, Avx, Avx2, Avx512f, Avx512dq, Avx512ifma, Avx512pf,
    Avx512er, Avx512cd, Avx512bw, Avx512vl, Avx512vbmi, Avx512vbmi2,
    Avx512vpopcntdq, Avx512vnni, Avx512vnniw4, Avx512fmaps4, Avx512bitalg,
    Avx512bfloat16, Avx512vp2intersect, Rdrand, Rdseed, MovBigEndian, Popcnt,
    Fma3, Fma4, Xop, Cas8B, Cas16B, Abm, Bmi1, Bmi2, TsxHle, TsxRtm, Adx, Sgx,
    Gfni, Aes, Vaes, Vpclmulqdq, Pclmulqdq, NxBit, Float16c, Sha, Clflush,
    ClflushOpt, Clwb, PrefetchWT1, Mpx

# The reason why we don't just evaluate these directly in the `let` variable
# list is so that we can internally organize features by their input (leaf)
# and output registers.
proc testX86Feature(feature: X86Feature): bool =
  let
    leaf1 {.global.} = cpuidX86(leaf = 1)
    leaf7 {.global.} = cpuidX86(leaf = 7)
    leaf8 {.global.} = cpuidX86(leaf = 0x80000001'i32)

  proc test(input, bit: int): bool =
    ((1 shl bit) and input) != 0

  # see: https://en.wikipedia.org/wiki/CPUID#Calling_CPUID
  # see: Intel® Architecture Instruction Set Extensions and Future Features
  #      Programming Reference
  result = case feature
    # leaf 1, edx
    of X87fpu:
      leaf1.edx.test(0)
    of Clflush:
      leaf1.edx.test(19)
    of Mmx:
      leaf1.edx.test(23)
    of Sse:
      leaf1.edx.test(25)
    of Sse2:
      leaf1.edx.test(26)
    of Hyperthreading:
      leaf1.edx.test(28)

    # leaf 1, ecx
    of Sse3:
      leaf1.ecx.test(0)
    of Pclmulqdq:
      leaf1.ecx.test(1)
    of IntelVtx:
      leaf1.ecx.test(5)
    of Ssse3:
      leaf1.ecx.test(9)
    of Fma3:
      leaf1.ecx.test(12)
    of Cas16B:
      leaf1.ecx.test(13)
    of Sse41:
      leaf1.ecx.test(19)
    of Sse42:
      leaf1.ecx.test(20)
    of MovBigEndian:
      leaf1.ecx.test(22)
    of Popcnt:
      leaf1.ecx.test(23)
    of Aes:
      leaf1.ecx.test(25)
    of Avx:
      leaf1.ecx.test(28)
    of Float16c:
      leaf1.ecx.test(29)
    of Rdrand:
      leaf1.ecx.test(30)
    of HypervisorPresence:
      leaf1.ecx.test(31)

    # leaf 7, ecx
    of PrefetchWT1:
      leaf7.ecx.test(0)
    of Avx512vbmi:
      leaf7.ecx.test(1)
    of Avx512vbmi2:
      leaf7.ecx.test(6)
    of Gfni:
      leaf7.ecx.test(8)
    of Vaes:
      leaf7.ecx.test(9)
    of Vpclmulqdq:
      leaf7.ecx.test(10)
    of Avx512vnni:
      leaf7.ecx.test(11)
    of Avx512bitalg:
      leaf7.ecx.test(12)
    of Avx512vpopcntdq:
      leaf7.ecx.test(14)

    # lead 7, eax
    of Avx512bfloat16:
      leaf7.eax.test(5)

    # leaf 7, ebx
    of Sgx:
      leaf7.ebx.test(2)
    of Bmi1:
      leaf7.ebx.test(3)
    of TsxHle:
      leaf7.ebx.test(4)
    of Avx2:
      leaf7.ebx.test(5)
    of Bmi2:
      leaf7.ebx.test(8)
    of TsxRtm:
      leaf7.ebx.test(11)
    of Mpx:
      leaf7.ebx.test(14)
    of Avx512f:
      leaf7.ebx.test(16)
    of Avx512dq:
      leaf7.ebx.test(17)
    of Rdseed:
      leaf7.ebx.test(18)
    of Adx:
      leaf7.ebx.test(19)
    of Avx512ifma:
      leaf7.ebx.test(21)
    of ClflushOpt:
      leaf7.ebx.test(23)
    of Clwb:
      leaf7.ebx.test(24)
    of Avx512pf:
      leaf7.ebx.test(26)
    of Avx512er:
      leaf7.ebx.test(27)
    of Avx512cd:
      leaf7.ebx.test(28)
    of Sha:
      leaf7.ebx.test(29)
    of Avx512bw:
      leaf7.ebx.test(30)
    of Avx512vl:
      leaf7.ebx.test(31)

    # leaf 7, edx
    of Avx512vnniw4:
      leaf7.edx.test(2)
    of Avx512fmaps4:
      leaf7.edx.test(3)
    of Avx512vp2intersect:
      leaf7.edx.test(8)

    # leaf 8, edx
    of NoSMT:
      leaf8.edx.test(1)
    of Cas8B:
      leaf8.edx.test(8)
    of NxBit:
      leaf8.edx.test(20)
    of MmxExt:
      leaf8.edx.test(22)
    of F3DNowEnhanced:
      leaf8.edx.test(30)
    of F3DNow:
      leaf8.edx.test(31)

    # leaf 8, ecx
    of Amdv:
      leaf8.ecx.test(2)
    of Abm:
      leaf8.ecx.test(5)
    of Sse4a:
      leaf8.ecx.test(6)
    of Prefetch:
      leaf8.ecx.test(8)
    of Xop:
      leaf8.ecx.test(11)
    of Fma4:
      leaf8.ecx.test(16)

let
  isHypervisorPresent* = testX86Feature(HypervisorPresence)
    ## **(x86 Only)**
    ##
    ## Reports `true` if this application is running inside of a virtual
    ## machine (this is by no means foolproof).

  hasSimultaneousMultithreading* =
    testX86Feature(Hyperthreading) or not testX86Feature(NoSMT)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware is utilizing simultaneous multithreading
    ## (branded as *"hyperthreads"* on Intel processors).

  hasIntelVtx* = testX86Feature(IntelVtx)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the Intel virtualization extensions (VT-x) are
    ## available.

  hasAmdv* = testX86Feature(Amdv)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the AMD virtualization extensions (AMD-V) are
    ## available.

  hasX87fpu* = testX86Feature(X87fpu)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use x87 floating-point instructions
    ## (includes support for single, double, and 80-bit percision floats as
    ## per IEEE 754-1985).
    ##
    ## By virtue of SSE2 enforced compliance on AMD64 CPUs, this should always
    ## be `true` on 64-bit x86 processors. It should be noted that support of
    ## these instructions is deprecated on 64-bit versions of Windows - see
    ## MSDN_.
    ##
    ## .. _MSDN: https://docs.microsoft.com/en-us/windows/win32/dxtecharts/sixty-four-bit-programming-for-game-developers#porting-applications-to-64-bit-platforms

  hasMmx* = testX86Feature(Mmx)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use MMX SIMD instructions.
    ##
    ## By virtue of SSE2 enforced compliance on AMD64 CPUs, this should always
    ## be `true` on 64-bit x86 processors. It should be noted that support of
    ## these instructions is deprecated on 64-bit versions of Windows (see
    ## MSDN_ for more info).
    ##
    ## .. _MSDN: https://docs.microsoft.com/en-us/windows/win32/dxtecharts/sixty-four-bit-programming-for-game-developers#porting-applications-to-64-bit-platforms

  hasMmxExt* = testX86Feature(MmxExt)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use "Extended MMX" SIMD
    ## instructions.
    ##
    ## By virtue of SSE2 enforced compliance on AMD64 CPUs, this should always
    ## be `true` on 64-bit x86 processors. It should be noted that support of
    ## these instructions is deprecated on 64-bit versions of Windows (see
    ## MSDN_ for more info).
    ##
    ## .. _MSDN: https://docs.microsoft.com/en-us/windows/win32/dxtecharts/sixty-four-bit-programming-for-game-developers#porting-applications-to-64-bit-platforms

  has3DNow* = testX86Feature(F3DNow)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use 3DNow! SIMD instructions.
    ##
    ## It should be noted that support of these instructions is deprecated on
    ## 64-bit versions of Windows (see MSDN_ for more info), and that the
    ## 3DNow! instructions (with an exception made for the prefetch
    ## instructions, see the `hasPrefetch` variable) have been phased out of
    ## AMD processors since 2010 (see `AMD Developer Central`_ for more info).
    ##
    ## .. _MSDN: https://docs.microsoft.com/en-us/windows/win32/dxtecharts/sixty-four-bit-programming-for-game-developers#porting-applications-to-64-bit-platforms
    ## .. _`AMD Developer Central`: https://web.archive.org/web/20131109151245/http://developer.amd.com/community/blog/2010/08/18/3dnow-deprecated/

  has3DNowEnhanced* = testX86Feature(F3DNowEnhanced)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use "Enhanced 3DNow!" SIMD
    ## instructions.
    ##
    ## It should be noted that support of these instructions is deprecated on
    ## 64-bit versions of Windows (see MSDN_ for more info), and that the
    ## 3DNow! instructions (with an exception made for the prefetch
    ## instructions, see the `hasPrefetch` variable) have been phased out of
    ## AMD processors since 2010 (see `AMD Developer Central`_ for more info).
    ##
    ## .. _MSDN: https://docs.microsoft.com/en-us/windows/win32/dxtecharts/sixty-four-bit-programming-for-game-developers#porting-applications-to-64-bit-platforms
    ## .. _`AMD Developer Central`: https://web.archive.org/web/20131109151245/http://developer.amd.com/community/blog/2010/08/18/3dnow-deprecated/

  hasPrefetch* = testX86Feature(Prefetch) or testX86Feature(F3DNow)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use the `PREFETCH` and `PREFETCHW`
    ## instructions. These instructions originally included as part of 3DNow!,
    ## but potentially indepdendent from the rest of it due to changes in
    ## contemporary AMD processors (see above).

  hasSse* = testX86Feature(Sse)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use the SSE (Streaming SIMD
    ## Extensions) 1.0 instructions, which introduced 128-bit SIMD on x86
    ## machines.
    ##
    ## By virtue of SSE2 enforced compliance on AMD64 CPUs, this should always
    ## be `true` on 64-bit x86 processors.

  hasSse2* = testX86Feature(Sse2)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use the SSE (Streaming SIMD
    ## Extensions) 2.0 instructions.
    ##
    ## By virtue of SSE2 enforced compliance on AMD64 CPUs, this should always
    ## be `true` on 64-bit x86 processors.

  hasSse3* = testX86Feature(Sse3)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use SSE (Streaming SIMD
    ## Extensions) 3.0 instructions.

  hasSsse3* = testX86Feature(Ssse3)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use Supplemental SSE (Streaming
    ## SIMD Extensions) 3.0 instructions.

  hasSse4a* = testX86Feature(Sse4a)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use Supplemental SSE (Streaming
    ## SIMD Extensions) 4a instructions.

  hasSse41* = testX86Feature(Sse41)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use Supplemental SSE (Streaming
    ## SIMD Extensions) 4.1 instructions.

  hasSse42* = testX86Feature(Sse42)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use Supplemental SSE (Streaming
    ## SIMD Extensions) 4.2 instructions.

  hasAvx* = testX86Feature(Avx)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
    ## 1.0 instructions, which introduced 256-bit SIMD on x86 machines along with
    ## addded reencoded versions of prior 128-bit SSE instructions into the more
    ## code-dense and non-backward compatible VEX (Vector Extensions) format.

  hasAvx2* = testX86Feature(Avx2)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
    ## 2.0 instructions.

  hasAvx512f* = testX86Feature(Avx512f)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
    ## 512-bit F (Foundation) instructions.

  hasAvx512dq* = testX86Feature(Avx512dq)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
    ## 512-bit DQ (Doubleword + Quadword) instructions.

  hasAvx512ifma* = testX86Feature(Avx512ifma)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
    ## 512-bit IFMA (Integer Fused-Multiply-Accumulation) instructions.

  hasAvx512pf* = testX86Feature(Avx512pf)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
    ## 512-bit PF (Prefetch) instructions.

  hasAvx512er* = testX86Feature(Avx512er)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
    ## 512-bit ER (Exponential and Reciprocal) instructions.

  hasAvx512cd* = testX86Feature(Avx512dq)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
    ## 512-bit CD (Conflict Detection) instructions.

  hasAvx512bw* = testX86Feature(Avx512bw)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
    ## 512-bit BW (Byte and Word) instructions.

  hasAvx512vl* = testX86Feature(Avx512vl)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
    ## 512-bit VL (Vector Length) instructions.

  hasAvx512vbmi* = testX86Feature(Avx512vbmi)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
    ## 512-bit VBMI (Vector Byte Manipulation) 1.0 instructions.

  hasAvx512vbmi2* = testX86Feature(Avx512vbmi2)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
    ## 512-bit VBMI (Vector Byte Manipulation) 2.0 instructions.

  hasAvx512vpopcntdq* = testX86Feature(Avx512vpopcntdq)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use the AVX (Advanced Vector
    ## Extensions) 512-bit `VPOPCNTDQ` (population count, i.e. determine
    ## number of flipped bits) instruction.

  hasAvx512vnni* = testX86Feature(Avx512vnni)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
    ## 512-bit VNNI (Vector Neural Network) instructions.

  hasAvx512vnniw4* = testX86Feature(Avx512vnniw4)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
    ## 512-bit 4VNNIW (Vector Neural Network Word Variable Percision)
    ## instructions.

  hasAvx512fmaps4* = testX86Feature(Avx512fmaps4)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
    ## 512-bit 4FMAPS (Fused-Multiply-Accumulation Single-percision)
    ## instructions.

  hasAvx512bitalg* = testX86Feature(Avx512bitalg)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
    ## 512-bit BITALG (Bit Algorithms) instructions.

  hasAvx512bfloat16* = testX86Feature(Avx512bfloat16)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
    ## 512-bit BFLOAT16 (8-bit exponent, 7-bit mantissa) instructions
    ## used by Intel DL (Deep Learning) Boost.

  hasAvx512vp2intersect* = testX86Feature(Avx512vp2intersect)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
    ## 512-bit VP2INTERSECT (Compute Intersections between Dualwords +
    ## Quadwords) instructions.

  hasRdrand* = testX86Feature(Rdrand)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for the `RDRAND` instruction,
    ## i.e. Intel on-CPU hardware random number generation.

  hasRdseed* = testX86Feature(Rdseed)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for the `RDSEED` instruction,
    ## i.e. Intel on-CPU hardware random number generation (used for seeding
    ## other PRNGs).

  hasMovBigEndian* = testX86Feature(MovBigEndian)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for the `MOVBE` instruction
    ## for endianness/byte-order switching.

  hasPopcnt* = testX86Feature(Popcnt)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for the `POPCNT` (population
    ## count, i.e. determine number of flipped bits) instruction.

  hasFma3* = testX86Feature(Fma3)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for the FMA3
    ## (Fused-Multiply-Accumulation 3-operand) SIMD instructions.

  hasFma4* = testX86Feature(Fma4)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for the FMA4
    ## (Fused-Multiply-Accumulation 4-operand) SIMD instructions.

  hasXop* = testX86Feature(Xop)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for the XOP (eXtended
    ## Operations) SIMD instructions. These instructions are exclusive to the
    ## Bulldozer AMD microarchitecture family (i.e. Bulldozer, Piledriver,
    ## Steamroller, and Excavator) and were phased out with the release of the
    ## Zen design.

  hasCas8b* = testX86Feature(Cas8b)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for the (`LOCK`-able)
    ## `CMPXCHG8B` 64-bit compare-and-swap instruction.

  hasCas16b* = testX86Feature(Cas16b)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for the (`LOCK`-able)
    ## `CMPXCHG16B` 128-bit compare-and-swap instruction.

  hasAbm* = testX86Feature(Abm)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for ABM (Advanced Bit
    ## Manipulation) insturctions (i.e. `POPCNT` and `LZCNT` for counting
    ## leading zeroes).

  hasBmi1* = testX86Feature(Bmi1)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for BMI (Bit Manipulation)
    ## 1.0 instructions.

  hasBmi2* = testX86Feature(Bmi2)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for BMI (Bit Manipulation)
    ## 2.0 instructions.

  hasTsxHle* = testX86Feature(TsxHle)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for HLE (Hardware Lock
    ## Elision) as part of Intel's TSX (Transactional Synchronization
    ## Extensions).

  hasTsxRtm* = testX86Feature(TsxRtm)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for RTM (Restricted
    ## Transactional Memory) as part of Intel's TSX (Transactional
    ## Synchronization Extensions).

  hasAdx* = testX86Feature(TsxHle)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for ADX (Multi-percision
    ## Add-Carry Extensions) insructions.

  hasSgx* = testX86Feature(Sgx)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for SGX (Software Guard
    ## eXtensions) memory encryption technology.

  hasGfni* = testX86Feature(Gfni)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for GFNI (Galois Field
    ## Affine Transformation) instructions.

  hasAes* = testX86Feature(Aes)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for AESNI (Advanced
    ## Encryption Standard) instructions.

  hasVaes* = testX86Feature(Vaes)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for VAES (Vectorized
    ## Advanced Encryption Standard) instructions.

  hasVpclmulqdq* = testX86Feature(Vpclmulqdq)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for `VCLMULQDQ` (512 and
    ## 256-bit Carryless Multiplication) instructions.

  hasPclmulqdq* = testX86Feature(VPclmulqdq)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for `PCLMULQDQ` (128-bit
    ## Carryless Multiplication) instructions.

  hasNxBit* = testX86Feature(NxBit)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for NX-bit (No-eXecute)
    ## technology for marking pages of memory as non-executable.

  hasFloat16c* = testX86Feature(Float16c)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for F16C instructions, used
    ## for converting 16-bit "half-percision" floating-point values to and
    ## from single-percision floating-point values.

  hasSha* = testX86Feature(Sha)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for SHA (Secure Hash
    ## Algorithm) instructions.

  hasClflush* = testX86Feature(Clflush)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for the `CLFLUSH`
    ## (Cache-line Flush) instruction.

  hasClflushOpt* = testX86Feature(ClflushOpt)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for the `CLFLUSHOPT`
    ## (Cache-line Flush Optimized) instruction.

  hasClwb* = testX86Feature(Clwb)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for the `CLWB` (Cache-line
    ## Write Back) instruction.


  hasPrefetchWT1* = testX86Feature(PrefetchWT1)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for the `PREFECTHWT1`
    ## instruction.

  hasMpx* = testX86Feature(Mpx)
    ## **(x86 Only)**
    ##
    ## Reports `true` if the hardware has support for MPX (Memory Protection
    ## eXtensions).
