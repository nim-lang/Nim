discard """
  action: run
  cmd: "nim c -d:icCompressBif -r $file"
"""

import std/[assertions, strutils]
import ../../compiler/icbifcompression

let original = repeat("NIF binary token data ", 1000)
let packed = compressBif(original)
doAssert packed.len < original.len
doAssert isCompressedBif(unsafeAddr packed[0], packed.len)
doAssert not isCompressedBif(unsafeAddr original[0], original.len)
let unpacked = decompressBif(unsafeAddr packed[0], packed.len)
doAssert unpacked.size == original.len
doAssert equalMem(unpacked.data, unsafeAddr original[0], original.len)
dealloc(unpacked.data)

var broken = packed
broken.setLen(broken.len - 1)
doAssertRaises IOError:
  discard decompressBif(unsafeAddr broken[0], broken.len)
