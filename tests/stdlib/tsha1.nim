import std/sha1

let hash1 = secureHash("a93tgj0p34jagp9[agjp98ajrhp9aej]")
doAssert hash1 == hash1
doAssert parseSecureHash($hash1) == hash1

template checkVector(s, exp: string) =
  doAssert secureHash(s) == parseSecureHash(exp)

checkVector("", "da39a3ee5e6b4b0d3255bfef95601890afd80709")
checkVector("abc", "a9993e364706816aba3e25717850c26c9cd0d89d")
checkVector("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
            "84983e441c3bd26ebaae4aa1f95129e5e54670f1")
