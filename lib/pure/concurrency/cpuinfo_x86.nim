
proc cpuidX86(eaxi, ecxi: int32): tuple[eax, ebx, ecx, edx: int32] =
  when defined(vcc):
    # limited inline asm support in vcc, so intrinsics, here we go:
    proc cpuidVcc(cpuInfo: ptr int32; functionID: int32)
      {.cdecl, importc: "__cpuidex", header: "intrin.h".}
    cpuidVcc(addr result.eax, eaxi, ecxi)
  else:
    var (eaxr, ebxr, ecxr, edxr) = (0'i32, 0'i32, 0'i32, 0'i32)
    asm """
      cpuid
      :"=a"(`eaxr`), "=b"(`ebxr`), "=c"(`ecxr`), "=d"(`edxr`)
      :"a"(`eaxi`), "c"(`ecxi`)"""
    (eaxr, ebxr, ecxr, edxr)

proc cpuNameX86(): string =
  var leaves {.global.} = cast[array[48, char]]([
    cpuidX86(eaxi = 0x80000002'i32, ecxi = 0),
    cpuidX86(eaxi = 0x80000003'i32, ecxi = 0),
    cpuidX86(eaxi = 0x80000004'i32, ecxi = 0)])
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

let
  leaf1 = cpuidX86(eaxi = 1, ecxi = 0)
  leaf7 = cpuidX86(eaxi = 7, ecxi = 0)
  leaf8 = cpuidX86(eaxi = 0x80000001'i32, ecxi = 0)

# The reason why we don't just evaluate these directly in the `let` variable
# list is so that we can internally organize features by their input (leaf)
# and output registers.
proc testX86Feature(feature: X86Feature): bool =
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
  isHypervisorPresentImpl = testX86Feature(HypervisorPresence)
  hasSimultaneousMultithreadingImpl =
    testX86Feature(Hyperthreading) or not testX86Feature(NoSMT)
  hasIntelVtxImpl = testX86Feature(IntelVtx)
  hasAmdvImpl = testX86Feature(Amdv)
  hasX87fpuImpl = testX86Feature(X87fpu)
  hasMmxImpl = testX86Feature(Mmx)
  hasMmxExtImpl = testX86Feature(MmxExt)
  has3DNowImpl = testX86Feature(F3DNow)
  has3DNowEnhancedImpl = testX86Feature(F3DNowEnhanced)
  hasPrefetchImpl = testX86Feature(Prefetch) or testX86Feature(F3DNow)
  hasSseImpl = testX86Feature(Sse)
  hasSse2Impl = testX86Feature(Sse2)
  hasSse3Impl = testX86Feature(Sse3)
  hasSsse3Impl = testX86Feature(Ssse3)
  hasSse4aImpl = testX86Feature(Sse4a)
  hasSse41Impl = testX86Feature(Sse41)
  hasSse42Impl = testX86Feature(Sse42)
  hasAvxImpl = testX86Feature(Avx)
  hasAvx2Impl = testX86Feature(Avx2)
  hasAvx512fImpl = testX86Feature(Avx512f)
  hasAvx512dqImpl = testX86Feature(Avx512dq)
  hasAvx512ifmaImpl = testX86Feature(Avx512ifma)
  hasAvx512pfImpl = testX86Feature(Avx512pf)
  hasAvx512erImpl = testX86Feature(Avx512er)
  hasAvx512cdImpl = testX86Feature(Avx512dq)
  hasAvx512bwImpl = testX86Feature(Avx512bw)
  hasAvx512vlImpl = testX86Feature(Avx512vl)
  hasAvx512vbmiImpl = testX86Feature(Avx512vbmi)
  hasAvx512vbmi2Impl = testX86Feature(Avx512vbmi2)
  hasAvx512vpopcntdqImpl = testX86Feature(Avx512vpopcntdq)
  hasAvx512vnniImpl = testX86Feature(Avx512vnni)
  hasAvx512vnniw4Impl = testX86Feature(Avx512vnniw4)
  hasAvx512fmaps4Impl = testX86Feature(Avx512fmaps4)
  hasAvx512bitalgImpl = testX86Feature(Avx512bitalg)
  hasAvx512bfloat16Impl = testX86Feature(Avx512bfloat16)
  hasAvx512vp2intersectImpl = testX86Feature(Avx512vp2intersect)
  hasRdrandImpl = testX86Feature(Rdrand)
  hasRdseedImpl = testX86Feature(Rdseed)
  hasMovBigEndianImpl = testX86Feature(MovBigEndian)
  hasPopcntImpl = testX86Feature(Popcnt)
  hasFma3Impl = testX86Feature(Fma3)
  hasFma4Impl = testX86Feature(Fma4)
  hasXopImpl = testX86Feature(Xop)
  hasCas8BImpl = testX86Feature(Cas8B)
  hasCas16BImpl = testX86Feature(Cas16B)
  hasAbmImpl = testX86Feature(Abm)
  hasBmi1Impl = testX86Feature(Bmi1)
  hasBmi2Impl = testX86Feature(Bmi2)
  hasTsxHleImpl = testX86Feature(TsxHle)
  hasTsxRtmImpl = testX86Feature(TsxRtm)
  hasAdxImpl = testX86Feature(TsxHle)
  hasSgxImpl = testX86Feature(Sgx)
  hasGfniImpl = testX86Feature(Gfni)
  hasAesImpl = testX86Feature(Aes)
  hasVaesImpl = testX86Feature(Vaes)
  hasVpclmulqdqImpl = testX86Feature(Vpclmulqdq)
  hasPclmulqdqImpl = testX86Feature(Pclmulqdq)
  hasNxBitImpl = testX86Feature(NxBit)
  hasFloat16cImpl = testX86Feature(Float16c)
  hasShaImpl = testX86Feature(Sha)
  hasClflushImpl = testX86Feature(Clflush)
  hasClflushOptImpl = testX86Feature(ClflushOpt)
  hasClwbImpl = testX86Feature(Clwb)
  hasPrefetchWT1Impl = testX86Feature(PrefetchWT1)
  hasMpxImpl = testX86Feature(Mpx)

# NOTE: We use procedures here (layered over the variables) to keep the API
# consistent and usable against possible future heterogenous systems with ISA
# differences between cores (a possibility that has historical precedents, for
# instance, the PPU/SPU relationship found on the IBM Cell). If future systems
# do end up having disparate ISA features across multiple cores, expect there to
# be a "cpuCore" argument added to the feature procs.

proc isHypervisorPresent*(): bool {.inline.} =
  return isHypervisorPresentImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if this application is running inside of a virtual machine
  ## (this is by no means foolproof).

proc hasSimultaneousMultithreading*(): bool {.inline.} =
  return hasSimultaneousMultithreadingImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware is utilizing simultaneous multithreading
  ## (branded as *"hyperthreads"* on Intel processors).

proc hasIntelVtx*(): bool {.inline.} =
  return hasIntelVtxImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the Intel virtualization extensions (VT-x) are available.

proc hasAmdv*(): bool {.inline.} =
  return hasAmdvImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the AMD virtualization extensions (AMD-V) are available.

proc hasX87fpu*(): bool {.inline.} =
  return hasX87fpuImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use x87 floating-point instructions
  ## (includes support for single, double, and 80-bit percision floats as per
  ## IEEE 754-1985).
  ##
  ## By virtue of SSE2 enforced compliance on AMD64 CPUs, this should always be
  ## `true` on 64-bit x86 processors. It should be noted that support of these
  ## instructions is deprecated on 64-bit versions of Windows - see MSDN_.
  ##
  ## .. _MSDN: https://docs.microsoft.com/en-us/windows/win32/dxtecharts/sixty-four-bit-programming-for-game-developers#porting-applications-to-64-bit-platforms

proc hasMmx*(): bool {.inline.} =
  return hasMmxImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use MMX SIMD instructions.
  ##
  ## By virtue of SSE2 enforced compliance on AMD64 CPUs, this should always be
  ## `true` on 64-bit x86 processors. It should be noted that support of these
  ## instructions is deprecated on 64-bit versions of Windows (see MSDN_ for
  ## more info).
  ##
  ## .. _MSDN: https://docs.microsoft.com/en-us/windows/win32/dxtecharts/sixty-four-bit-programming-for-game-developers#porting-applications-to-64-bit-platforms

proc hasMmxExt*(): bool {.inline.} =
  return hasMmxExtImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use "Extended MMX" SIMD instructions.
  ##
  ## By virtue of SSE2 enforced compliance on AMD64 CPUs, this should always be
  ## `true` on 64-bit x86 processors. It should be noted that support of these
  ## instructions is deprecated on 64-bit versions of Windows (see MSDN_ for
  ## more info).
  ##
  ## .. _MSDN: https://docs.microsoft.com/en-us/windows/win32/dxtecharts/sixty-four-bit-programming-for-game-developers#porting-applications-to-64-bit-platforms

proc has3DNow*(): bool {.inline.} =
  return has3DNowImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use 3DNow! SIMD instructions.
  ##
  ## It should be noted that support of these instructions is deprecated on
  ## 64-bit versions of Windows (see MSDN_ for more info), and that the 3DNow!
  ## instructions (with an exception made for the prefetch instructions, see the
  ## `hasPrefetch` variable) have been phased out of AMD processors since 2010
  ## (see `AMD Developer Central`_ for more info).
  ##
  ## .. _MSDN: https://docs.microsoft.com/en-us/windows/win32/dxtecharts/sixty-four-bit-programming-for-game-developers#porting-applications-to-64-bit-platforms
  ## .. _`AMD Developer Central`: https://web.archive.org/web/20131109151245/http://developer.amd.com/community/blog/2010/08/18/3dnow-deprecated/

proc has3DNowEnhanced*(): bool {.inline.} =
  return has3DNowEnhancedImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use "Enhanced 3DNow!" SIMD instructions.
  ##
  ## It should be noted that support of these instructions is deprecated on
  ## 64-bit versions of Windows (see MSDN_ for more info), and that the 3DNow!
  ## instructions (with an exception made for the prefetch instructions, see the
  ## `hasPrefetch` variable) have been phased out of AMD processors since 2010
  ## (see `AMD Developer Central`_ for more info).
  ##
  ## .. _MSDN: https://docs.microsoft.com/en-us/windows/win32/dxtecharts/sixty-four-bit-programming-for-game-developers#porting-applications-to-64-bit-platforms
  ## .. _`AMD Developer Central`: https://web.archive.org/web/20131109151245/http://developer.amd.com/community/blog/2010/08/18/3dnow-deprecated/

proc hasPrefetch*(): bool {.inline.} =
  return hasPrefetchImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use the `PREFETCH` and `PREFETCHW`
  ## instructions. These instructions originally included as part of 3DNow!, but
  ## potentially indepdendent from the rest of it due to changes in contemporary
  ## AMD processors (see above).

proc hasSse*(): bool {.inline.} =
  return hasSseImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use the SSE (Streaming SIMD Extensions)
  ## 1.0 instructions, which introduced 128-bit SIMD on x86 machines.
  ##
  ## By virtue of SSE2 enforced compliance on AMD64 CPUs, this should always be
  ## `true` on 64-bit x86 processors.

proc hasSse2*(): bool {.inline.} =
  return hasSse2Impl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use the SSE (Streaming SIMD Extensions)
  ## 2.0 instructions.
  ##
  ## By virtue of SSE2 enforced compliance on AMD64 CPUs, this should always be
  ## `true` on 64-bit x86 processors.

proc hasSse3*(): bool {.inline.} =
  return hasSse3Impl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use SSE (Streaming SIMD Extensions) 3.0
  ## instructions.

proc hasSsse3*(): bool {.inline.} =
  return hasSsse3Impl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use Supplemental SSE (Streaming SIMD
  ## Extensions) 3.0 instructions.

proc hasSse4a*(): bool {.inline.} =
  return hasSse4aImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use Supplemental SSE (Streaming SIMD
  ## Extensions) 4a instructions.

proc hasSse41*(): bool {.inline.} =
  return hasSse41Impl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use Supplemental SSE (Streaming SIMD
  ## Extensions) 4.1 instructions.

proc hasSse42*(): bool {.inline.} =
  return hasSse42Impl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use Supplemental SSE (Streaming SIMD
  ## Extensions) 4.2 instructions.

proc hasAvx*(): bool {.inline.} =
  return hasAvxImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 1.0 instructions, which introduced 256-bit SIMD on x86 machines along with
  ## addded reencoded versions of prior 128-bit SSE instructions into the more
  ## code-dense and non-backward compatible VEX (Vector Extensions) format.

proc hasAvx2*(): bool {.inline.} =
  return hasAvx2Impl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions) 2.0
  ## instructions.

proc hasAvx512f*(): bool {.inline.} =
  return hasAvx512fImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit F (Foundation) instructions.

proc hasAvx512dq*(): bool {.inline.} =
  return hasAvx512dqImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit DQ (Doubleword + Quadword) instructions.

proc hasAvx512ifma*(): bool {.inline.} =
  return hasAvx512ifmaImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit IFMA (Integer Fused Multiply Accumulation) instructions.

proc hasAvx512pf*(): bool {.inline.} =
  return hasAvx512pfImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit PF (Prefetch) instructions.

proc hasAvx512er*(): bool {.inline.} =
  return hasAvx512erImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit ER (Exponential and Reciprocal) instructions.

proc hasAvx512cd*(): bool {.inline.} =
  return hasAvx512cdImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit CD (Conflict Detection) instructions.

proc hasAvx512bw*(): bool {.inline.} =
  return hasAvx512bwImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit BW (Byte and Word) instructions.

proc hasAvx512vl*(): bool {.inline.} =
  return hasAvx512vlImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit VL (Vector Length) instructions.

proc hasAvx512vbmi*(): bool {.inline.} =
  return hasAvx512vbmiImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit VBMI (Vector Byte Manipulation) 1.0 instructions.

proc hasAvx512vbmi2*(): bool {.inline.} =
  return hasAvx512vbmi2Impl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit VBMI (Vector Byte Manipulation) 2.0 instructions.

proc hasAvx512vpopcntdq*(): bool {.inline.} =
  return hasAvx512vpopcntdqImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use the AVX (Advanced Vector Extensions)
  ## 512-bit `VPOPCNTDQ` (population count, i.e. determine number of flipped
  ## bits) instruction.

proc hasAvx512vnni*(): bool {.inline.} =
  return hasAvx512vnniImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit VNNI (Vector Neural Network) instructions.

proc hasAvx512vnniw4*(): bool {.inline.} =
  return hasAvx512vnniw4Impl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit 4VNNIW (Vector Neural Network Word Variable Percision)
  ## instructions.

proc hasAvx512fmaps4*(): bool {.inline.} =
  return hasAvx512fmaps4Impl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit 4FMAPS (Fused-Multiply-Accumulation Single-percision) instructions.

proc hasAvx512bitalg*(): bool {.inline.} =
  return hasAvx512bitalgImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit BITALG (Bit Algorithms) instructions.

proc hasAvx512bfloat16*(): bool {.inline.} =
  return hasAvx512bfloat16Impl
  ## **(x86 Only)**
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit BFLOAT16 (8-bit exponent, 7-bit mantissa) instructions used by
  ## Intel DL (Deep Learning) Boost.

proc hasAvx512vp2intersect*(): bool {.inline.} =
  return hasAvx512vp2intersectImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware can use AVX (Advanced Vector Extensions)
  ## 512-bit VP2INTERSECT (Compute Intersections between Dualwords + Quadwords)
  ## instructions.

proc hasRdrand*(): bool {.inline.} =
  return hasRdrandImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the `RDRAND` instruction,
  ## i.e. Intel on-CPU hardware random number generation.

proc hasRdseed*(): bool {.inline.} =
  return hasRdseedImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the `RDSEED` instruction,
  ## i.e. Intel on-CPU hardware random number generation (used for seeding other
  ## PRNGs).

proc hasMovBigEndian*(): bool {.inline.} =
  return hasMovBigEndianImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the `MOVBE` instruction for
  ## endianness/byte-order switching.

proc hasPopcnt*(): bool {.inline.} =
  return hasPopcntImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the `POPCNT` (population
  ## count, i.e. determine number of flipped bits) instruction.

proc hasFma3*(): bool {.inline.} =
  return hasFma3Impl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the FMA3 (Fused Multiply
  ## Accumulation 3-operand) SIMD instructions.

proc hasFma4*(): bool {.inline.} =
  return hasFma4Impl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the FMA4 (Fused Multiply
  ## Accumulation 4-operand) SIMD instructions.

proc hasXop*(): bool {.inline.} =
  return hasXopImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the XOP (eXtended
  ## Operations) SIMD instructions. These instructions are exclusive to the
  ## Bulldozer AMD microarchitecture family (i.e. Bulldozer, Piledriver,
  ## Steamroller, and Excavator) and were phased out with the release of the Zen
  ## design.

proc hasCas8B*(): bool {.inline.} =
  return hasCas8BImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the (`LOCK`-able)
  ## `CMPXCHG8B` 64-bit compare-and-swap instruction.

proc hasCas16B*(): bool {.inline.} =
  return hasCas16BImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the (`LOCK`-able)
  ## `CMPXCHG16B` 128-bit compare-and-swap instruction.

proc hasAbm*(): bool {.inline.} =
  return hasAbmImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for ABM (Advanced Bit
  ## Manipulation) insturctions (i.e. `POPCNT` and `LZCNT` for counting leading
  ## zeroes).

proc hasBmi1*(): bool {.inline.} =
  return hasBmi1Impl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for BMI (Bit Manipulation) 1.0
  ## instructions.

proc hasBmi2*(): bool {.inline.} =
  return hasBmi2Impl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for BMI (Bit Manipulation) 2.0
  ## instructions.

proc hasTsxHle*(): bool {.inline.} =
  return hasTsxHleImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for HLE (Hardware Lock Elision)
  ## as part of Intel's TSX (Transactional Synchronization Extensions).

proc hasTsxRtm*(): bool {.inline.} =
  return hasTsxRtmImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for RTM (Restricted
  ## Transactional Memory) as part of Intel's TSX (Transactional Synchronization
  ## Extensions).

proc hasAdx*(): bool {.inline.} =
  return hasAdxImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for ADX (Multi-percision
  ## Add-Carry Extensions) insructions.

proc hasSgx*(): bool {.inline.} =
  return hasSgxImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for SGX (Software Guard
  ## eXtensions) memory encryption technology.

proc hasGfni*(): bool {.inline.} =
  return hasGfniImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for GFNI (Galois Field Affine
  ## Transformation) instructions.

proc hasAes*(): bool {.inline.} =
  return hasAesImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for AESNI (Advanced Encryption
  ## Standard) instructions.

proc hasVaes*(): bool {.inline.} =
  return hasVaesImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for VAES (Vectorized Advanced
  ## Encryption Standard) instructions.

proc hasVpclmulqdq*(): bool {.inline.} =
  return hasVpclmulqdqImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for `VCLMULQDQ` (512 and 256-bit
  ## Carryless Multiplication) instructions.

proc hasPclmulqdq*(): bool {.inline.} =
  return hasPclmulqdqImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for `PCLMULQDQ` (128-bit
  ## Carryless Multiplication) instructions.

proc hasNxBit*(): bool {.inline.} =
  return hasNxBitImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for NX-bit (No-eXecute)
  ## technology for marking pages of memory as non-executable.

proc hasFloat16c*(): bool {.inline.} =
  return hasFloat16cImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for F16C instructions, used for
  ## converting 16-bit "half-percision" floating-point values to and from
  ## single-percision floating-point values.

proc hasSha*(): bool {.inline.} =
  return hasShaImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for SHA (Secure Hash Algorithm)
  ## instructions.

proc hasClflush*(): bool {.inline.} =
  return hasClflushImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the `CLFLUSH` (Cache-line
  ## Flush) instruction.

proc hasClflushOpt*(): bool {.inline.} =
  return hasClflushOptImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the `CLFLUSHOPT` (Cache-line
  ## Flush Optimized) instruction.

proc hasClwb*(): bool {.inline.} =
  return hasClwbImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the `CLWB` (Cache-line Write
  ## Back) instruction.

proc hasPrefetchWT1*(): bool {.inline.} =
  return hasPrefetchWT1Impl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for the `PREFECTHWT1`
  ## instruction.

proc hasMpx*(): bool {.inline.} =
  return hasMpxImpl
  ## **(x86 Only)**
  ##
  ## Reports `true` if the hardware has support for MPX (Memory Protection
  ## eXtensions).
