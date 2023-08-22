# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

import strformat, strutils, json,  hashes
import common
import ../../dist/checksums/src/checksums/sha1

type
  InvalidSha1HashError* = object of NimbleError
    ## Represents an error caused by invalid value of a sha1 hash.

  Sha1Hash* = object
    ## Type representing a sha1 hash value. It can only be created by special
    ## procedure which validates the input.
    hashValue: string

const
  notSetSha1Hash* = Sha1Hash(hashValue: "")

template `$`*(sha1Hash: Sha1Hash): string = sha1Hash.hashValue
template `%`*(sha1Hash: Sha1Hash): JsonNode = %sha1Hash.hashValue
template `==`*(lhs, rhs: Sha1Hash): bool = lhs.hashValue == rhs.hashValue
template hash*(sha1Hash: Sha1Hash): Hash = sha1Hash.hashValue.hash

proc invalidSha1Hash(value: string): ref InvalidSha1HashError =
  ## Creates a new exception object for an invalid sha1 hash value.
  result = newNimbleError[InvalidSha1HashError](
    &"The string '{value}' does not represent a valid sha1 hash value.")

proc initSha1Hash*(value: string): Sha1Hash =
  ## Creates a new `Sha1Hash` object from a string by making all latin letters
  ## lower case and validating the transformed value. In the case the supplied
  ## string is not a valid sha1 hash value then raises an `InvalidSha1HashError`
  ## exception.
  if value == "":
    return notSetSha1Hash
  let value = value.toLowerAscii
  if not isValidSha1Hash(value):
    raise invalidSha1Hash(value)
  return Sha1Hash(hashValue: value)

proc initFromJson*(dst: var Sha1Hash, jsonNode: JsonNode,
                   jsonPath: var string) =
  case jsonNode.kind
  of JNull: dst = notSetSha1Hash
  of JObject: dst = initSha1Hash(jsonNode["hashValue"].str)
  of JString: dst = initSha1Hash(jsonNode.str)
  else:
    assert false,
      "The `jsonNode` must have one of {JNull, JObject, JString} kinds."

when isMainModule:
  import unittest

  test "init sha1":
    check initSha1Hash("") == notSetSha1Hash
    expect InvalidSha1HashError: discard initSha1Hash("9")
    expect InvalidSha1HashError:
      discard initSha1Hash("99345ce680cd3e48acdb9ab4212e4bd9bf9358g7")
    expect InvalidSha1HashError:
      discard initSha1Hash("99345ce680cd3e48acdb9ab4212e4bd9bf9358b")
    check $initSha1Hash("99345ce680cd3e48acdb9ab4212e4bd9bf9358b7") ==
                        "99345ce680cd3e48acdb9ab4212e4bd9bf9358b7"
    check $initSha1Hash("99345CE680CD3E48ACDB9AB4212E4BD9BF9358B7") ==
                        "99345ce680cd3e48acdb9ab4212e4bd9bf9358b7"
