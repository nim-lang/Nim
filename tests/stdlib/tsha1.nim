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

proc testIsValidSha1Hash =
  doAssert not isValidSha1Hash("")
  doAssert not isValidSha1Hash("042D4BE2B90ED0672E717D71850ABDB0A2D19CD11")
  doAssert not isValidSha1Hash("042G4BE2B90ED0672E717D71850ABDB0A2D19CD1")
  doAssert isValidSha1Hash("042D4BE2B90ED0672E717D71850ABDB0A2D19CD1")
  doAssert isValidSha1Hash("042d4be2b90ed0672e717d71850abdb0a2d19cd1")
  doAssert isValidSha1Hash("042d4be2b90ed0672e717D71850ABDB0A2D19CD1")

testIsValidSha1Hash()
