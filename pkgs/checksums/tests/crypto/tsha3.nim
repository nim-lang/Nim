discard """
targets: "c cpp js"
"""

import checksums/sha3
import std/assertions

const testMessage = """
  Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
  ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco
  laboris nisi ut aliquip ex ea commodo consequat.
"""

block: # Test standard hashing functions
  doAssert $Sha3_224.secureHash(testMessage) == "ef599b341207a816ad98e02c515d16ba2ceb4bbe159f44a8a9593e0f"
  doAssert $Sha3_256.secureHash(testMessage) == "b2a55a8c3903d5540d78cfe5158cd61ce1a73c413a16d34d820ff6d60eadf032"
  doAssert $Sha3_384.secureHash(testMessage) == "1f482cf35de0ab6532a7f4bb323ec9286a5cdd2334ef60707b881b28717182f6e0075fbea9897067b67f2dd7ff446cd2"
  doAssert $Sha3_512.secureHash(testMessage) == "43a0776ca3e9266c5db2ad133f325250bed73e03eea4ba612a76b3f7d4d5ba8ccadf6b3e9156b9dc4bf78bdcf8f526bc6d6ebcde394be8a70116a6132c1d9263"

block: # Test extendable-output functions (SHAKE128)
  var extendedOutput: array[48, char]
  var shake = initShake(Shake128)

  shake.update(testMessage)
  shake.finalize()

  shake.shakeOut(extendedOutput)
  doAssert $extendedOutput == "ec5246775023af7b971786342c6fd7c3753d2b112da2a42ced7f593f5b733b94eb8460a66dde246db2a2230d785f0086"

  shake.shakeOut(extendedOutput)
  doAssert $extendedOutput == "8507dc5fcd58e3a44398e3b36f3bc40e33d8da3a3214b383e98b388f4cee85bbed6108a4195f95f05a03cd7b52bec953"

block: # Test extendable-output functions (SHAKE256)
  var extendedOutput: array[48, char]
  var shake = initShake(Shake256)

  shake.update(testMessage)
  shake.finalize()

  shake.shakeOut(extendedOutput)
  doAssert $extendedOutput == "23b874203158e5157c12746d7a5424e3a5487172201a3a05ddb7c07d53ac32b89201752b6e2795b8696fa57f3ae44b2e"

  shake.shakeOut(extendedOutput)
  doAssert $extendedOutput == "decf0e5c85d85c2080cb91dfbfae98056d48c2a4f052a4202adc3c625d6d358cbd9d55510a192ec6959900a6da70e2ae"

block: # Test extendable-output functions (SHAKE512)
  var extendedOutput: array[48, char]
  var shake = initShake(Shake512)

  shake.update(testMessage)
  shake.finalize()

  shake.shakeOut(extendedOutput)
  doAssert $extendedOutput == "fdc05fa35c446d81a74380491d6f7375f9526169d04a1abc06c2e01b5888baaa3026a1d1504c69c1cce6b3eb2cefb518"

  shake.shakeOut(extendedOutput)
  doAssert $extendedOutput == "d1e4e09324f9c1c8fffe34f0d67a357adc649b687bc4644340c540ca85aac9407a5ed63e698aba48f68b0bfe5bc0faaf"