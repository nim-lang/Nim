discard """
  targets: "c cpp"
  matrix: "--mm:arc; --mm:orc"
"""

block:
  type
    PublicKey = array[32, uint8]
    PrivateKey = array[64, uint8]

  proc ed25519_create_keypair(publicKey: ptr PublicKey; privateKey: ptr PrivateKey) =
    publicKey[][0] = uint8(88)

  type
    KeyPair = object
      public: PublicKey
      private: PrivateKey

  proc initKeyPair(): KeyPair =
    ed25519_create_keypair(result.public.addr, result.private.addr)

  let keys = initKeyPair()
  doAssert keys.public[0] == 88


template minIndexByIt: untyped =
  var other = 3
  other

proc bug20303() =
  var hlibs = @["hello", "world", "how", "are", "you"]
  let res = hlibs[minIndexByIt()]
  doAssert res == "are"

bug20303()

proc main() = # todo bug with templates
  block: # bug #11267
    var a: seq[char] = block: @[]
    doAssert a == @[]
    # 2
    proc b: seq[string] =
      discard
      @[]
    doAssert b() == @[]
static: main()
main()


type Obj = tuple
  value: int
  arr: seq[int]

proc bug(): seq[Obj] =
  result.add (value: 0, arr: @[])
  result[^1].value = 1
  result[^1].arr.add 1

# bug #19990
let s = bug()
doAssert s[0] == (value: 1, arr: @[1])
