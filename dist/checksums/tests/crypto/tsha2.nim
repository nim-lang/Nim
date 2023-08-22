discard """
targets: "c cpp js"
"""

import checksums/sha2
import std/assertions

const testMessage = """
  Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
  ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco
  laboris nisi ut aliquip ex ea commodo consequat.
"""

block:
  doAssert $Sha_224.secureHash(testMessage) == "5932f0aef6e3b0e76678bbfc54ffe201d2cf1997c43bfe7121cd97bf"
  doAssert $Sha_256.secureHash(testMessage) == "660d86f292b60431dbfda275b38c62993f95f278c5006bffc4f33621f721ff69"
  doAssert $Sha_384.secureHash(testMessage) == "3ce9b6bb7bc651c49d8fafab32e500d7ea598928518f88fddb30ac0122aabaa827c5285258499f921e2c6ea4874be137"
  doAssert $Sha_512.secureHash(testMessage) == "6328dce1242d6aaa4ff1c74b7c5bea3583c8c457020f905e829581cd1e3135f3ceb1a695a2c1ba8ccf22700b66bf83444e4c7d5171bd82fe7f3370183d7036ff"