#
#
#              Nim's Runtime Library
#        (c) Copyright 2023 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
## [SHA-3 (Secure Hash Algorithm 3)](https://en.wikipedia.org/wiki/SHA-3) is a
## cryptographic hash function which takes an input and produces a value known
## as a message digest.
##
## It provides both fixed size algorithms that generate a one-shot message digest
## of a determinate size as well as an *extendable-output function* (XOF) variant
## that can produce any message digest lengths desired.
##
## Implemented Algorithms
## ----------------------
## Fixed size functions:
##  - SHA3-224
##  - SHA3-256
##  - SHA3-384
##  - SHA3-512
##
## Extended-output functions:
##  - SHAKE128
##  - SHAKE256
##  - SHAKE512
##
## For convenience, this module provides output-length type checked functions for the
## implemented fixed size functions via `initSha3_224`, `initSha3_256`, `initSha3_384`
## and `initSha3_512`.
## These functions provide a `digest` overload returning a correctly sized message digest
## array.
##
## If more relaxed types are required, an "unchecked" `Sha3State` can be used, but care must
## be taken to provide `digest` with a correctly sized `dest` array.
##
runnableExamples:
  var hasher = initSha3_256()

  hasher.update("The quick brown fox ")
  hasher.update("jumps over the lazy dog")

  let digest = hasher.digest()

  assert $digest == "69070dda01975c8c120c3aada1b282394e7f032fa9cf32f4cb2259a0897dfc04"

runnableExamples:
  var xof = initShake(Shake128)

  xof.update("The quick brown fox ")
  xof.update("jumps over the lazy dog")
  xof.finalize()

  var digest: array[16, char]

  xof.shakeOut(digest)
  assert $digest == "f4202e3c5852f9182a0430fd8144f0a7"

  xof.shakeOut(digest)
  assert $digest == "4b95e7417ecae17db0f8cfeed0e3e66e"


import private/sha_utils
import std/algorithm

when not defined(js):
  import std/bitops

export sha_utils.`$`

const
  rounds: int = 24
  roundConstants: array[24, CompatUint64] = [
    0x0000000000000001'u64.CompatUint64,
    0x0000000000008082'u64.CompatUint64,
    0x800000000000808A'u64.CompatUint64,
    0x8000000080008000'u64.CompatUint64,
    0x000000000000808B'u64.CompatUint64,
    0x0000000080000001'u64.CompatUint64,
    0x8000000080008081'u64.CompatUint64,
    0x8000000000008009'u64.CompatUint64,
    0x000000000000008A'u64.CompatUint64,
    0x0000000000000088'u64.CompatUint64,
    0x0000000080008009'u64.CompatUint64,
    0x000000008000000A'u64.CompatUint64,
    0x000000008000808B'u64.CompatUint64,
    0x800000000000008B'u64.CompatUint64,
    0x8000000000008089'u64.CompatUint64,
    0x8000000000008003'u64.CompatUint64,
    0x8000000000008002'u64.CompatUint64,
    0x8000000000000080'u64.CompatUint64,
    0x000000000000800A'u64.CompatUint64,
    0x800000008000000A'u64.CompatUint64,
    0x8000000080008081'u64.CompatUint64,
    0x8000000000008080'u64.CompatUint64,
    0x0000000080000001'u64.CompatUint64,
    0x8000000080008008'u64.CompatUint64,
  ]

  rotc: array[24, uint8] = [
    1, 3, 6, 10, 15, 21, 28, 36, 45, 55, 2, 14,
    27, 41, 56, 8, 25, 43, 62, 18, 39, 61, 20, 44
  ]

  piln: array[24, uint8] = [
    10, 7, 11, 17, 18, 3, 5, 16, 8, 21, 24, 4,
    15, 23, 19, 13, 12, 2, 20, 14, 22, 9, 6, 1
  ]

type
  KeccakStateData = array[25, CompatUint64]
  KeccakState = object
    st: KeccakStateData

    mdlen: int
    rsiz: int
    pt: int

# Keccak sponge index and index assign
func spongeCoordIndex(x, y: int): int {.inline.} =
  x + 5 * y

proc `[]`(st: KeccakStateData; x, y: int): CompatUint64 {.inline.} =
  st[spongeCoordIndex(x, y)]

proc `[]=`(st: var KeccakStateData; x, y: int; z: CompatUint64) {.inline.} =
  st[spongeCoordIndex(x, y)] = z

when not defined(js):
  # Definitions for the native backend
  when cpuEndian == littleEndian:
    # In little endian architectures, we can treat the `uint64`s as an `array[8, uint8]`
    # which Keccak really seems to like.
    proc absorbSingle(st: var KeccakStateData; j: int; c: uint8) =
      var pt = cast[ptr UncheckedArray[uint8]](addr st)

      pt[j] = pt[j] xor c

    proc squeezeSingle(st: var KeccakStateData; j: int): uint8 =
      var pt = cast[ptr UncheckedArray[uint8]](addr st)

      pt[j]

  else:
    proc absorbSingle(st: var KeccakStateData; j: int; c: uint8) =
      var i = j div 8
      var p = j mod 8

      st[i] = uint64(c) shl (8 * p) xor st[i]

    proc squeezeSingle(st: var KeccakStateData; j: int): uint8 =
      var i = j div 8
      var p = j mod 8

      uint8((st[i] shr (8 * p)) and 0xff)

else:
  # Definitions for the JavaScript backend
  proc absorbSingle(st: var KeccakStateData; j: int; c: uint8) =
    var i = j div 8
    var p = (j mod 8) div 4
    var q = j mod 4

    if p == 0:
      st[i].lo = uint32(c) shl (8 * q) xor st[i].lo
    else:
      st[i].hi = uint32(c) shl (8 * q) xor st[i].hi

  proc squeezeSingle(st: var KeccakStateData; j: int): uint8 =
    var i = j div 8
    var p = (j mod 8) div 4
    var q = j mod 4

    if p == 0:
      uint8(st[i].lo shr (8 * q)) and 0xff
    else:
      uint8(st[i].hi shr (8 * q)) and 0xff

# Main Keccak permutation function
proc permute(st: var KeccakStateData) =
  # Perform rounds
  for round in 0..<rounds:
    var c: array[5, CompatUint64]

    # [Keccak Reference, Section 2.3.2]
    for x in 0..<5:
      c[x] =
        st[x, 0] xor
        st[x, 1] xor
        st[x, 2] xor
        st[x, 3] xor
        st[x, 4]

    for x in 0..<5:
      let d = c[(x + 4) mod 5] xor rotateLeftBits(c[(x + 1) mod 5], 1)

      for y in 0..<5:
        st[x, y] = st[x, y] xor d

    # [Keccak Reference, Sections 2.3.3 and 2.3.4]
    var bc: array[5, CompatUint64]
    var t = st[1]

    for r in 0..<rounds:
      let j = piln[r]

      bc[0] = st[j]
      st[j] = t.rotateLeftBits(rotc[r].int)

      t = bc[0]

    # [Keccak Reference, Section 2.3.1]
    for y in 0..<5:
      var temp: array[5, CompatUint64] = [
        st[0, y],
        st[1, y],
        st[2, y],
        st[3, y],
        st[4, y],
      ]

      for x in 0..<5:
        st[x, y] = temp[x] xor (not temp[(x+1) mod 5] and temp[(x+2) mod 5])

    # [Keccak Reference, Section 2.3.5]
    #  (optimized out LFSR for round constants)
    st[0] = st[0] xor roundConstants[round]

#
# Low-level interface to SHA3-{224,256,384,512} and SHAKE{128,256}
#
func initKeccakState(mdlen: int): KeccakState =
  # NOTE: Unsure about the naming. Even though this seems to be more
  #       in line with NEP-1, the sha1 module uses `newSha1State` even
  #       though `Sha1State` is not a reference counted object.
  KeccakState(
    mdlen: mdlen,
    rsiz: 200 - 2*mdlen,
    pt: 0)

proc update(ctx: var KeccakState; data: openArray[char]) =
  for octet in data:
    ctx.st.absorbSingle(ctx.pt, uint8(octet))

    inc ctx.pt

    if ctx.pt >= ctx.rsiz:
      ctx.st.permute()
      ctx.pt = 0


# SHA-3-*
proc finalize(ctx: var KeccakState) =
  ctx.st.absorbSingle(ctx.pt, 0x06'u8)
  ctx.st.absorbSingle(ctx.rsiz - 1, 0x80'u8)

  ctx.st.permute()

proc squeezeOut(ctx: var KeccakState; dest: var openArray[char]) =
  # assert dest.len >= ctx.mdlen for more "technically correct", if inconvenient, behaviour?
  for i in 0..<min(dest.len, ctx.mdlen):
    dest[i] = ctx.st.squeezeSingle(i).char

  if not defined(js):
    ctx.st.fill(0'u64)

# SHAKE-128 and SHAKE-256
proc shakeFinalize(ctx: var KeccakState) =
  ctx.st.absorbSingle(ctx.pt, 0x1F'u8)
  ctx.st.absorbSingle(ctx.rsiz - 1, 0x80'u8)

  ctx.st.permute()
  ctx.pt = 0

proc shakeOut(ctx: var KeccakState; dest: var openArray[char]) =
  for i in 0..<dest.len:
    if ctx.pt >= ctx.rsiz:
      ctx.st.permute()
      ctx.pt = 0

    dest[i] = ctx.st.squeezeSingle(ctx.pt).char

    inc ctx.pt

#
# Higher level interface to fixed output SHA3-* instances
#
type
  Sha3Instance* = enum
    ## Selects a specific SHA3 instance with well known message digest lengths and properties.

    Sha3_224 ## SHA3-224 with an output size of 28 bytes
    Sha3_256 ## SHA3-256 with an output size of 32 bytes
    Sha3_384 ## SHA3-384 with an output size of 48 bytes
    Sha3_512 ## SHA3-512 with an output size of 64 bytes

  Sha3Digest_224* = array[28, char] ## SHA3-224 output digest.
  Sha3Digest_256* = array[32, char] ## SHA3-256 output digest.
  Sha3Digest_384* = array[48, char] ## SHA3-384 output digest.
  Sha3Digest_512* = array[64, char] ## SHA3-512 output digest.

  Sha3State* = distinct KeccakState
    ## An unchecked SHA3 state created from a specific `Sha3Instance`.
    ##
    ## Unchecked meaning the user has to make sure that the target buffer has enough room
    ## to store the resulting digest, otherwise `digest` will truncate the output.

  Sha3StateStatic*[instance: static Sha3Instance] = distinct Sha3State
    ## A statically checked SHA3 state created from a specific `Sha3Instance`.

func digestLength*(instance: Sha3Instance): int =
  ## Returns the message digest size for the selected SHA3 instance.
  case instance
    of Sha3_224: 28
    of Sha3_256: 32
    of Sha3_384: 48
    of Sha3_512: 64

func initSha3*(instance: Sha3Instance): Sha3State =
  ## Constructs a new unchecked SHA3 state for the selected instance `instance`.
  Sha3State(initKeccakState(instance.digestLength()))

func initSha3StateStatic*(instance: static Sha3Instance): Sha3StateStatic[instance] =
  ## Constructs a new statically checked SHA3 state for the selected instance `instance`.
  Sha3StateStatic[instance](initSha3(instance))

func initSha3_224*(): Sha3StateStatic[Sha3_224] = initSha3StateStatic(Sha3_224)
  ## Constructs a new statically checked state for the SHA3-224 instance.

func initSha3_256*(): Sha3StateStatic[Sha3_256] = initSha3StateStatic(Sha3_256)
  ## Constructs a new statically checked state for the SHA3-256 instance.

func initSha3_384*(): Sha3StateStatic[Sha3_384] = initSha3StateStatic(Sha3_384)
  ## Constructs a new statically checked state for the SHA3-384 instance.

func initSha3_512*(): Sha3StateStatic[Sha3_512] = initSha3StateStatic(Sha3_512)
  ## Constructs a new statically checked state for the SHA3-512 instance.

# {.borrow.} doesn't seem to work through our static wrapper
proc update*[instance: static Sha3Instance](
    state: var Sha3StateStatic[instance];
    data: openArray[char]) =
  ## Updates the given `Sha3StateStatic` with the provided buffer `data`.
  KeccakState(state).update(data)

proc update*(
  state: var Sha3State;
  data: openArray[char]) {.borrow.}

  ## Updates the given `Sha3State` with the provided buffer `data`.


proc digest*(state: var Sha3StateStatic[Sha3_224]): Sha3Digest_224 =
  ## Finishes and returns the completed SHA3-224 message digest.
  state.KeccakState.finalize()
  state.KeccakState.squeezeOut(result)

proc digest*(state: var Sha3StateStatic[Sha3_256]): Sha3Digest_256 =
  ## Finishes and returns the completed SHA3-256 message digest.
  state.KeccakState.finalize()
  state.KeccakState.squeezeOut(result)

proc digest*(state: var Sha3StateStatic[Sha3_384]): Sha3Digest_384 =
  ## Finishes and returns the completed SHA3-284 message digest.
  state.KeccakState.finalize()
  state.KeccakState.squeezeOut(result)

proc digest*(state: var Sha3StateStatic[Sha3_512]): Sha3Digest_512 =
  ## Finishes and returns the completed SHA3-512 message digest.
  state.KeccakState.finalize()
  state.KeccakState.squeezeOut(result)

proc digest*(
    state: var Sha3State;
    dest: var openArray[char]): int =
  ## Finishes, stores the completed message digest in `dest` and returns the number of bytes
  ## written in `dest`.
  ##
  ## If `dest` is not big enough to contain the digest produced by the selected instance,
  ## everything that would overflow is truncated.
  state.KeccakState.finalize()
  state.KeccakState.squeezeOut(dest)

  result = state.KeccakState.mdlen

#
# Higher level interface to variable output Shake-* instances
#
type
  ShakeInstance* = enum
    ## Selects a specific Shake instance with well known properties.

    Shake128 ## Shake-128
    Shake256 ## Shake-256
    Shake512 ## Shake-512 (Keccak proposal; not officially included in SHA3)

  ShakeState* = distinct KeccakState
    ## A Shake state created from a specific `ShakeInstance`.

func digestLength*(instance: ShakeInstance): int =
  ## Returns the message digest size for the selected Shake instance.
  case instance
    of Shake128: result = 16
    of Shake256: result = 32
    of Shake512: result = 64

func initShake*(instance: ShakeInstance): ShakeState =
  ## Constructs a new Shake state for the selected instance `instance`.
  ShakeState(initKeccakState(instance.digestLength))

proc update*(state: var ShakeState; data: openArray[char]) {.borrow.}
  ## Updates the given `ShakeState` with the provided buffer `data`.

proc finalize*(state: var ShakeState) =
  ## Finishes the input digestion state of the given `ShakeState` and readies
  ## it for message digest retrieval.
  state.KeccakState.shakeFinalize()

proc shakeOut*(state: var ShakeState; dest: var openArray[char]) =
  ## "Shakes out" a part of the variable length Shake message digest. The `ShakeState`
  ## must be `finalize`d before calling this procedure.
  ##
  ## It can be invoked multiple times with user selectable buffer sizes. In particular,
  ## it is guaranteed that the same digest is extracted in both of the following examples,
  ## given the same `state`:
  ##
  ## ```
  ##   var digest: array[32, byte]
  ##
  ##   state.shakeOut(digestPart)
  ## ```
  ##
  ## ```
  ##   var digestA: array[16, byte]
  ##   var digestB: array[16, byte]
  ##
  ##   state.shakeOut(digestA)
  ##   state.shakeOut(digestB)
  ## ```
  state.KeccakState.shakeOut(dest)


proc secureHash*(instance: static Sha3Instance; data: openArray[char]): auto =
  ## Convenience wrapper around the standard "init, update, digest" sequence with a statically
  ## selected SHA instance.
  var ctx = initSha3StateStatic(instance)

  ctx.update(data)
  ctx.digest()

proc secureHash*(instance: Sha3Instance; data: openArray[char]): seq[char] =
  ## Convenience wrapper around the standard "init, update, digest" sequence with a runtime
  ## selected SHA instance.
  result = newSeqOfCap[char](instance.digestLength())
  result.setLen instance.digestLength()

  var ctx = initSha3(instance)

  ctx.update(data)

  # We have allocated the correct amount of space, no need to check the result
  discard ctx.digest(result)