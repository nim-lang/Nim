discard """
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
