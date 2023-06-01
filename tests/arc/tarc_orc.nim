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

block: # bug #21974
  type Test[T] = ref object
      values : seq[T]
      counter: int

  proc newTest[T](): Test[T] =
      result         = new(Test[T])
      result.values  = newSeq[T](16)
      result.counter = 0

  proc push[T](self: Test[T], value: T) =
      self.counter += 1
      if self.counter >= self.values.len:
          self.values.setLen(self.values.len * 2)
      self.values[self.counter - 1] = value

  proc pop[T](self: Test[T]): T =
      result         = self.values[0]
      self.values[0] = self.values[self.counter - 1] # <--- This line
      self.counter  -= 1


  type X = tuple
      priority: int
      value   : string

  var a = newTest[X]()
  a.push((1, "One"))
  doAssert a.pop.value == "One"
