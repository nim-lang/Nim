# This module implements the RFC 4122 specification for generating universally unique identifiers
# http://en.wikipedia.org/wiki/Universally_unique_identifier

# This module is a work-in-progress
# If you want to help with the implementation, take a loot at:
# http://dsource.org/projects/tango/docs/current/tango.util.uuid.Uuid.html

type TUuid* = array[0..15, char]

when defined(windows):
  # This is actually available only on Windows 2000+
  type PUuid* {.importc: "UUID __RPC_FAR *", header: "<Rpc.h>".} = ptr TUuid
  proc uuid1Sys*(uuid: PUuid) {.importc: "UuidCreateSequential", header: "<Rpc.h>".}

else:
  type PUuid {.importc: "uuid_t", header: "<uuid/uuid.h>".} = ptr TUuid
  proc uuid1Sys*(uuid: PUuid) {.importc: "uuid_generate_time", header: "<uuid/uuid.h>".}

# v1 UUIDs include the MAC address of the machine generating the ID and a timestamp
# This scheme has the strongest guaranty of uniqueness, but discloses when the ID was generated
proc uuidMacTime* : TUuid = uuid1Sys(addr(result))

# v4 UUID are created entirely using a random number generator.
# Some bits have fixed value in order to indicate the UUID type
proc uuidRandom*[RandomGenerator](rand: RandomGenerator) : TUuid = nil

# v3 and v5 UUIDs are derived from given namespace and name using a secure hashing algorithm.
# v3 uses MD5, v5 uses SHA1.
proc uuidByName*[Hash](namespace: TUuid, name: string, hasher: Hash, v: int) : TUuid = nil

