
# bug #14136

type
  MDigest*[bits: static[int]] = object
    ## Message digest type
    data*: array[bits div 8, byte]

  Sha2Context*[bits: static[int],
               bsize: static[int],
               T: uint32|uint64] = object
    count: array[2, T]
    state: array[8, T]
    buffer: array[bsize, byte]

  sha256* = Sha2Context[256, 64, uint32]

template hmacSizeBlock*(h: typedesc): int =
  when (h is Sha2Context):
    int(h.bsize)
  else:
    {.fatal: "Choosen hash primitive is not yet supported!".}

type
  HMAC*[HashType] = object
    ## HMAC context object.
    mdctx: HashType
    opadctx: HashType
    ipad: array[HashType.hmacSizeBlock, byte]
    opad: array[HashType.hmacSizeBlock, byte]

func hkdfExtract*[T;S,I: char|byte](ctx: var HMAC[T],
                     prk: var MDigest[T.bits], # <------- error here "Error: type expected"
                     salt: openArray[S],
                     ikm: openArray[I]
                    ) =
  discard

var ctx: HMAC[sha256]
var prk: MDigest[sha256.bits]
let salt = [byte 0x00, 0x01, 0x02]
let ikm = "CompletelyRandomInput"

ctx.hkdfExtract(prk, salt, ikm)
