#
#
#              Nim's Runtime Library
#        (c) Copyright 2023 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
## [SHA-2 (Secure Hash Algorithm 2)](https://en.wikipedia.org/wiki/SHA-2) is a
## cryptographic hash function which takes an input and produces a value known
## as a message digest.
##
## It provides fixed size algorithms that generate a one-shot message digest
## of a determinate size.
##
## Implemented Algorithms
## ----------------------
## Fixed size functions:
##  - SHA-224
##  - SHA-256
##  - SHA-384
##  - SHA-512
##
## For convenience, this module provides output-length type checked functions for the
## implemented fixed size functions via `initSha_224`, `initSha_256`, `initSha_384`
## and `initSha_512`.
## These functions provide a `digest` overload returning a correctly sized message digest
## array.
##
## If more relaxed types are required, an "unchecked" `Sha2State` can be used, but care must
## be taken to provide `digest` with a correctly sized `dest` array.
##
import private/sha_utils
import std/[algorithm, bitops, assertions]

export sha_utils.`$`

runnableExamples:
  var hasher = initSha_256()

  hasher.update("The quick brown fox ")
  hasher.update("jumps over the lazy dog")

  let digest = hasher.digest()

  assert $digest == "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592"

runnableExamples:
  var hasher = initSha_384()

  hasher.update("The quick brown fox ")
  hasher.update("jumps over the lazy dog")

  let digest = hasher.digest()

  assert $digest == "ca737f1014a48f4c0b6dd43cb177b0afd9e5169367544c494011e3317dbf9a509cb1e5dc1e85a941bbee3d7f2afbc9b1"

const
  # Lots of constants for SHA2

  # SHA-224 hash initializers
  sha224HashInits: array[8, uint32] = [
    0xc1059ed8'u32, 0x367cd507'u32, 0x3070dd17'u32, 0xf70e5939'u32,
    0xffc00b31'u32, 0x68581511'u32, 0x64f98fa7'u32, 0xbefa4fa4'u32
  ]

  # SHA-256 hash initializers
  sha256HashInits: array[8, uint32] = [
    0x6a09e667'u32, 0xbb67ae85'u32, 0x3c6ef372'u32, 0xa54ff53a'u32,
    0x510e527f'u32, 0x9b05688c'u32, 0x1f83d9ab'u32, 0x5be0cd19'u32
  ]

  # SHA-384 hash initializers
  sha384HashInits: array[8, CompatUint64] = [
    0xcbbb9d5dc1059ed8'u64.CompatUint64,
    0x629a292a367cd507'u64.CompatUint64,
    0x9159015a3070dd17'u64.CompatUint64,
    0x152fecd8f70e5939'u64.CompatUint64,
    0x67332667ffc00b31'u64.CompatUint64,
    0x8eb44a8768581511'u64.CompatUint64,
    0xdb0c2e0d64f98fa7'u64.CompatUint64,
    0x47b5481dbefa4fa4'u64.CompatUint64
  ]

  # SHA-512 hash initializers
  sha512HashInits: array[8, CompatUint64] = [
    0x6a09e667f3bcc908'u64.CompatUint64,
    0xbb67ae8584caa73b'u64.CompatUint64,
    0x3c6ef372fe94f82b'u64.CompatUint64,
    0xa54ff53a5f1d36f1'u64.CompatUint64,
    0x510e527fade682d1'u64.CompatUint64,
    0x9b05688c2b3e6c1f'u64.CompatUint64,
    0x1f83d9abfb41bd6b'u64.CompatUint64,
    0x5be0cd19137e2179'u64.CompatUint64
  ]


  # SHA-224/SHA-256 round constants
  sha256RoundConstants: array[64, uint32] = [
    0x428a2f98'u32, 0x71374491'u32, 0xb5c0fbcf'u32, 0xe9b5dba5'u32,
    0x3956c25b'u32, 0x59f111f1'u32, 0x923f82a4'u32, 0xab1c5ed5'u32,
    0xd807aa98'u32, 0x12835b01'u32, 0x243185be'u32, 0x550c7dc3'u32,
    0x72be5d74'u32, 0x80deb1fe'u32, 0x9bdc06a7'u32, 0xc19bf174'u32,
    0xe49b69c1'u32, 0xefbe4786'u32, 0x0fc19dc6'u32, 0x240ca1cc'u32,
    0x2de92c6f'u32, 0x4a7484aa'u32, 0x5cb0a9dc'u32, 0x76f988da'u32,
    0x983e5152'u32, 0xa831c66d'u32, 0xb00327c8'u32, 0xbf597fc7'u32,
    0xc6e00bf3'u32, 0xd5a79147'u32, 0x06ca6351'u32, 0x14292967'u32,
    0x27b70a85'u32, 0x2e1b2138'u32, 0x4d2c6dfc'u32, 0x53380d13'u32,
    0x650a7354'u32, 0x766a0abb'u32, 0x81c2c92e'u32, 0x92722c85'u32,
    0xa2bfe8a1'u32, 0xa81a664b'u32, 0xc24b8b70'u32, 0xc76c51a3'u32,
    0xd192e819'u32, 0xd6990624'u32, 0xf40e3585'u32, 0x106aa070'u32,
    0x19a4c116'u32, 0x1e376c08'u32, 0x2748774c'u32, 0x34b0bcb5'u32,
    0x391c0cb3'u32, 0x4ed8aa4a'u32, 0x5b9cca4f'u32, 0x682e6ff3'u32,
    0x748f82ee'u32, 0x78a5636f'u32, 0x84c87814'u32, 0x8cc70208'u32,
    0x90befffa'u32, 0xa4506ceb'u32, 0xbef9a3f7'u32, 0xc67178f2'u32
  ]

  # SHA-384/SHA-512 round constants
  sha512RoundConstants: array[80, CompatUint64] = [
    0x428a2f98d728ae22'u64.CompatUint64, 0x7137449123ef65cd'u64.CompatUint64,
    0xb5c0fbcfec4d3b2f'u64.CompatUint64, 0xe9b5dba58189dbbc'u64.CompatUint64,
    0x3956c25bf348b538'u64.CompatUint64, 0x59f111f1b605d019'u64.CompatUint64,
    0x923f82a4af194f9b'u64.CompatUint64, 0xab1c5ed5da6d8118'u64.CompatUint64,
    0xd807aa98a3030242'u64.CompatUint64, 0x12835b0145706fbe'u64.CompatUint64,
    0x243185be4ee4b28c'u64.CompatUint64, 0x550c7dc3d5ffb4e2'u64.CompatUint64,
    0x72be5d74f27b896f'u64.CompatUint64, 0x80deb1fe3b1696b1'u64.CompatUint64,
    0x9bdc06a725c71235'u64.CompatUint64, 0xc19bf174cf692694'u64.CompatUint64,
    0xe49b69c19ef14ad2'u64.CompatUint64, 0xefbe4786384f25e3'u64.CompatUint64,
    0x0fc19dc68b8cd5b5'u64.CompatUint64, 0x240ca1cc77ac9c65'u64.CompatUint64,
    0x2de92c6f592b0275'u64.CompatUint64, 0x4a7484aa6ea6e483'u64.CompatUint64,
    0x5cb0a9dcbd41fbd4'u64.CompatUint64, 0x76f988da831153b5'u64.CompatUint64,
    0x983e5152ee66dfab'u64.CompatUint64, 0xa831c66d2db43210'u64.CompatUint64,
    0xb00327c898fb213f'u64.CompatUint64, 0xbf597fc7beef0ee4'u64.CompatUint64,
    0xc6e00bf33da88fc2'u64.CompatUint64, 0xd5a79147930aa725'u64.CompatUint64,
    0x06ca6351e003826f'u64.CompatUint64, 0x142929670a0e6e70'u64.CompatUint64,
    0x27b70a8546d22ffc'u64.CompatUint64, 0x2e1b21385c26c926'u64.CompatUint64,
    0x4d2c6dfc5ac42aed'u64.CompatUint64, 0x53380d139d95b3df'u64.CompatUint64,
    0x650a73548baf63de'u64.CompatUint64, 0x766a0abb3c77b2a8'u64.CompatUint64,
    0x81c2c92e47edaee6'u64.CompatUint64, 0x92722c851482353b'u64.CompatUint64,
    0xa2bfe8a14cf10364'u64.CompatUint64, 0xa81a664bbc423001'u64.CompatUint64,
    0xc24b8b70d0f89791'u64.CompatUint64, 0xc76c51a30654be30'u64.CompatUint64,
    0xd192e819d6ef5218'u64.CompatUint64, 0xd69906245565a910'u64.CompatUint64,
    0xf40e35855771202a'u64.CompatUint64, 0x106aa07032bbd1b8'u64.CompatUint64,
    0x19a4c116b8d2d0c8'u64.CompatUint64, 0x1e376c085141ab53'u64.CompatUint64,
    0x2748774cdf8eeb99'u64.CompatUint64, 0x34b0bcb5e19b48a8'u64.CompatUint64,
    0x391c0cb3c5c95a63'u64.CompatUint64, 0x4ed8aa4ae3418acb'u64.CompatUint64,
    0x5b9cca4f7763e373'u64.CompatUint64, 0x682e6ff3d6b2b8a3'u64.CompatUint64,
    0x748f82ee5defb2fc'u64.CompatUint64, 0x78a5636f43172f60'u64.CompatUint64,
    0x84c87814a1f0ab72'u64.CompatUint64, 0x8cc702081a6439ec'u64.CompatUint64,
    0x90befffa23631e28'u64.CompatUint64, 0xa4506cebde82bde9'u64.CompatUint64,
    0xbef9a3f7b2c67915'u64.CompatUint64, 0xc67178f2e372532b'u64.CompatUint64,
    0xca273eceea26619c'u64.CompatUint64, 0xd186b8c721c0c207'u64.CompatUint64,
    0xeada7dd6cde0eb1e'u64.CompatUint64, 0xf57d4f7fee6ed178'u64.CompatUint64,
    0x06f067aa72176fba'u64.CompatUint64, 0x0a637dc5a2c898a6'u64.CompatUint64,
    0x113f9804bef90dae'u64.CompatUint64, 0x1b710b35131c471b'u64.CompatUint64,
    0x28db77f523047d84'u64.CompatUint64, 0x32caab7b40c72493'u64.CompatUint64,
    0x3c9ebe0a15c9bebc'u64.CompatUint64, 0x431d67c49c100d4c'u64.CompatUint64,
    0x4cc5d4becb3e42b6'u64.CompatUint64, 0x597f299cfc657e2a'u64.CompatUint64,
    0x5fcb6fab3ad6faec'u64.CompatUint64, 0x6c44198c4a475817'u64.CompatUint64
  ]

type
  ShaContextVariant[T; n, r: static int] = object
    bitlen: CompatUint64
    mdlen: int

    datalen: int
    data: array[n, uint8]
    state: array[8, T]

  Sha256Context = ShaContextVariant[uint32,       64,  64]
  Sha512Context = ShaContextVariant[CompatUint64, 128, 80]

  ShaContext = object
    case isSha512: bool
      of false: sha256: Sha256Context
      of true:  sha512: Sha512Context

# Second "constants" and helpers section, compile-time dispatched
# based on the specific SHA2 variant.

func ch(x, y, z: uint32 | CompatUint64): auto {.inline.} =
  x and y xor (not x) and z

func maj(x, y, z: uint32 | CompatUint64): auto {.inline.} =
  x and y xor x and z xor y and z

func ep(x: uint32 | CompatUint64; p: auto): auto {.inline.} =
  x.rotateRightBits(p[0]) xor
  x.rotateRightBits(p[1]) xor
  x.rotateRightBits(p[2])

func sig(x: uint32 | CompatUint64; p: auto): auto {.inline.} =
  x.rotateRightBits(p[0]) xor
  x.rotateRightBits(p[1]) xor
  (x shr p[2])

# SHA-256 ep and sig functions
func ep0(ctx: typedesc[Sha256Context], x: uint32): uint32 {.inline.} =
  ep(x, (2, 13, 22))

func ep1(ctx: typedesc[Sha256Context], x: uint32): uint32 {.inline.} =
  ep(x, (6, 11, 25))

func sig0(ctx: typedesc[Sha256Context], x: uint32): uint32 {.inline.} =
  sig(x, (7, 18, 3))

func sig1(ctx: typedesc[Sha256Context], x: uint32): uint32 {.inline.} =
  sig(x, (17, 19, 10))

# SHA-512 ep and sig functions
func ep0(ctx: typedesc[Sha512Context], x: CompatUint64): CompatUint64 {.inline.} =
  ep(x, (28, 34, 39))

func ep1(ctx: typedesc[Sha512Context], x: CompatUint64): CompatUint64 {.inline.} =
  ep(x, (14, 18, 41))

func sig0(ctx: typedesc[Sha512Context], x: CompatUint64): CompatUint64 {.inline.} =
  sig(x, (1, 8, 7))

func sig1(ctx: typedesc[Sha512Context], x: CompatUint64): CompatUint64 {.inline.} =
  sig(x, (19, 61, 6))

# SHA-256 + SHA-512 main parameters (Block lengths, rounds and round constants)
func blockLength[T; n, r: static int](ctx: typedesc[ShaContextVariant[T, n, r]]): int {.inline.} = n

func bitLengthBytes(ctx: typedesc[Sha256Context]): int  {.inline.} = 8
func bitLengthBytes(ctx: typedesc[Sha512Context]): int  {.inline.} = 16

template roundConstant(ctx: typedesc[Sha256Context]; round: int): uint32 =
  sha256RoundConstants[round]

template roundConstant(ctx: typedesc[Sha512Context]; round: int): CompatUint64 =
  sha512RoundConstants[round]

# SHA-256 + SHA-512 shared helper functions and templates

# Helper templates for plucking certain bytes out of a uint64
# or SplitUint64.
#
# 0x00112233_44556677.pluckChar(0) == 0x00
# 0x00112233_44556677.pluckChar(5) == 0x55
template pluckChar(x: uint32; p: int): char =
  char(x shr (24 - p * 8) and 0xFF)

when CompatUint64 is not uint64:
  template pluckChar(x: CompatUint64; p: int): char =
    if p > 3: x.lo.pluckChar(p)
    else:     x.hi.pluckChar(p - 4)
else:
  template pluckChar(x: uint64; p: int): char =
    char(x shr (56 - p * 8) and 0xFF)

# Helpers end, main SHA algorithm functions follow

func initShaContextVariant(mdlen: static int): auto =
  when mdlen == 28:
    result = Sha256Context(state: sha224HashInits)
  elif mdlen == 32:
    result = Sha256Context(state: sha256HashInits)
  elif mdlen == 48:
    result = Sha512Context(state: sha384HashInits)
  elif mdlen == 64:
    result = Sha512Context(state: sha512HashInits)
  else:
    {.error: "Invalid SHA variant".}

  result.mdlen = mdlen
  result.datalen = 0
  result.bitlen = 0'u64

func shaInitState(mdlen: int): ShaContext =
  result = ShaContext(isSha512: mdlen > 32)

  case mdlen
    of 28: result.sha256 = initShaContextVariant(28)
    of 32: result.sha256 = initShaContextVariant(32)
    of 48: result.sha512 = initShaContextVariant(48)
    of 64: result.sha512 = initShaContextVariant(64)
    else:
      # Unreachable
      assert false

# Core SHA-256/SHA-512 functions
func shaTransform[T; n, r: static int](ctx: var ShaContextVariant[T, n, r]) =
  type H = typeof(ctx)

  ## The basic, low level, SHA-256 and SHA-512 transformation loop
  ## parameterized over everything non-constant.
  var m: array[r, T]

  # Load the input into m[0..<16]
  for i in 0..<16:
    for j in 0..<sizeof(T):
      m[i] = m[i] or (ctx.data[sizeof(T)*i + j].uint8.T shl ((sizeof(T) - 1 - j)*8))

  # Blend the input into m[16..<rounds]
  for i in 16..<r:
    m[i] =
      H.sig1(m[i - 2]) +
      H.sig0(m[i - 15]) +
      m[i - 7] +
      m[i - 16]

  # Start permutation
  var
    (a, b, c, d, e, f, g, h) = (
      ctx.state[0], ctx.state[1], ctx.state[2], ctx.state[3],
      ctx.state[4], ctx.state[5], ctx.state[6], ctx.state[7])

  # Perform rounds
  for r in 0..<r:
    let t1 = (h + H.ep1(e) + ch(e, f, g) + H.roundConstant(r) + m[r])
    let t2 = (H.ep0(a) + maj(a, b, c))

    (h, g, f, e, d, c, b, a) = (g, f, e, d + t1, c, b, a, t1 + t2)

  # Update state with permutation
  ctx.state[0] += a
  ctx.state[1] += b
  ctx.state[2] += c
  ctx.state[3] += d
  ctx.state[4] += e
  ctx.state[5] += f
  ctx.state[6] += g
  ctx.state[7] += h

proc shaUpdate[T; n, r: static int](
    ctx: var ShaContextVariant[T, n, r],
    input: openArray[char]) =

  for octet in input:
    ctx.data[ctx.datalen] = octet.uint8

    inc ctx.datalen

    if ctx.datalen == n:
      ctx.shaTransform()

      ctx.bitlen += uint64(n * 8)
      ctx.datalen = 0

proc shaFinalize[T; n, r: static int](
    ctx: var ShaContextVariant[T, n, r];
    dest: var openArray[char]) =

  type H = typeof(ctx)

  # Write end marker and pad final block with 0
  ctx.data[ctx.datalen] = 0x80
  ctx.data.fill(ctx.datalen + 1, ctx.data.high, 0)

  ctx.bitlen += uint64(ctx.datalen * 8)

  # If writing the end marker caused the block to fill up
  # enough so that we can't write the total bit length, we
  # need to process another chunk for it.
  if ctx.datalen + 1 > H.blockLength - H.bitLengthBytes:
    ctx.shaTransform()
    ctx.data.fill(0)

  # Write bit length as big endian of `lengthBytes` length
  let cbitlen: CompatUint64 = uint64(ctx.bitlen)

  # While SHA-512 has 128 bits of bit-length storage, we can only
  # address 64 of those. 2^64 bits provides about ~2.3 exabytes
  # of capacity.
  for b in 0..<8:
    ctx.data[n - 1 - b] = uint8 cbitlen.pluckChar(8 - 1 - b)

  ctx.shaTransform()

  for i in 0..<sizeof(T):
    for j in 0..<ctx.mdlen div sizeof(T):
      if i + sizeof(T)*j > ctx.mdlen:
        return

      dest[i + sizeof(T)*j] = ctx.state[j].pluckChar(i)

  ctx.data.fill(0)

  when not defined(js):
    # CompatUint64 is not a natural number in JavaScript.
    ctx.state.fill(0)

# Dispatcher methods
proc update(state: var ShaContext; data: openArray[char]) =
  if state.isSha512:
    state.sha512.shaUpdate(data)
  else:
    state.sha256.shaUpdate(data)

proc finalize(state: var ShaContext; dest: var openArray[char]) =
  if state.isSha512:
    state.sha512.shaFinalize(dest)

  else:
    state.sha256.shaFinalize(dest)

#
# Higher level interface to fixed output SHA-* instances
#
type
  ShaInstance* = enum
    ## Selects a specific SHA instance with well known message digest lengths and properties.

    Sha_224 ## SHA-224 with an output size of 28 bytes (truncated from SHA-256)
    Sha_256 ## SHA-256 with an output size of 32 bytes
    Sha_384 ## SHA-384 with an output size of 48 bytes (truncated from SHA-512)
    Sha_512 ## SHA-512 with an output size of 64 bytes

  ShaDigest_224* = array[28, char] ## SHA-224 output digest.
  ShaDigest_256* = array[32, char] ## SHA-256 output digest.
  ShaDigest_384* = array[48, char] ## SHA-384 output digest.
  ShaDigest_512* = array[64, char] ## SHA-512 output digest.

  ShaState* = distinct ShaContext
    ## An unchecked SHA state created from a specific `ShaInstance`.
    ##
    ## Unchecked meaning the user has to make sure that the target buffer has enough room
    ## to store the resulting digest, otherwise `digest` will truncate the output.

  ShaStateStatic*[instance: static ShaInstance] = distinct ShaState
    ## A statically checked SHA state created from a specific `ShaInstance`.

func digestLength*(instance: ShaInstance): int =
  ## Returns the message digest size for the selected SHA instance.
  case instance
    of Sha_224: 28
    of Sha_256: 32
    of Sha_384: 48
    of Sha_512: 64

func initSha*(instance: ShaInstance): ShaState =
  ## Constructs a new unchecked SHA state for the selected instance `instance`.
  shaInitState(instance.digestLength()).ShaState

func initShaStateStatic*(instance: static ShaInstance): ShaStateStatic[instance] =
  ## Constructs a new statically checked SHA state for the selected instance `instance`.
  ShaStateStatic[instance](initSha(instance))

func initSha_224*(): ShaStateStatic[Sha_224] = initShaStateStatic(Sha_224)
  ## Constructs a new statically checked state for the SHA-224 instance.

func initSha_256*(): ShaStateStatic[Sha_256] = initShaStateStatic(Sha_256)
  ## Constructs a new statically checked state for the SHA-256 instance.

func initSha_384*(): ShaStateStatic[Sha_384] = initShaStateStatic(Sha_384)
  ## Constructs a new statically checked state for the SHA-384 instance.

func initSha_512*(): ShaStateStatic[Sha_512] = initShaStateStatic(Sha_512)
  ## Constructs a new statically checked state for the SHA-512 instance.

# {.borrow.} doesn't seem to work through our static wrapper
proc update*[instance: static ShaInstance](
    state: var ShaStateStatic[instance];
    data: openArray[char]) =
  ## Updates the given `ShaStateStatic` with the provided buffer `data`.
  ShaContext(state).update(data)

proc update*(
  state: var ShaState;
  data: openArray[char]) {.borrow.}

  ## Updates the given `ShaState` with the provided buffer `data`.


proc digest*(state: var ShaStateStatic[Sha_224]): ShaDigest_224 =
  ## Finishes and returns the completed SHA-224 message digest.
  state.ShaContext.finalize(result)

proc digest*(state: var ShaStateStatic[Sha_256]): ShaDigest_256 =
  ## Finishes and returns the completed SHA-256 message digest.
  state.ShaContext.finalize(result)

proc digest*(state: var ShaStateStatic[Sha_384]): ShaDigest_384 =
  ## Finishes and returns the completed SHA-284 message digest.
  state.ShaContext.finalize(result)

proc digest*(state: var ShaStateStatic[Sha_512]): ShaDigest_512 =
  ## Finishes and returns the completed SHA-512 message digest.
  state.ShaContext.finalize(result)

proc digest*(
    state: var ShaState;
    dest: var openArray[char]): int =
  ## Finishes, stores the completed message digest in `dest` and returns the number of bytes
  ## written in `dest`.
  ##
  ## If `dest` is not big enough to contain the digest produced by the selected instance,
  ## everything that would overflow is truncated.
  state.ShaContext.finalize(dest)

  result = if state.ShaContext.isSha512:
    state.ShaContext.sha512.mdlen
  else:
    state.ShaContext.sha256.mdlen

proc secureHash*(instance: static ShaInstance; data: openArray[char]): auto =
  ## Convenience wrapper around the standard "init, update, digest" sequence with a statically
  ## selected SHA instance.
  var ctx = initShaStateStatic(instance)

  ctx.update(data)
  ctx.digest()

proc secureHash*(instance: ShaInstance; data: openArray[char]): seq[char] =
  ## Convenience wrapper around the standard "init, update, digest" sequence with a runtime
  ## selected SHA instance.
  result = newSeqOfCap[char](instance.digestLength())
  result.setLen instance.digestLength()

  var ctx = initSha(instance)

  ctx.update(data)

  # We have allocated the correct amount of space, no need to check the result
  discard ctx.digest(result)
