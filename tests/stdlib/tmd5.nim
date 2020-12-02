import md5

assert(getMD5("Franz jagt im komplett verwahrlosten Taxi quer durch Bayern") ==
  "a3cca2b2aa1e3b5b3b5aad99a8529074")
assert(getMD5("Frank jagt im komplett verwahrlosten Taxi quer durch Bayern") ==
  "7e716d0e702df0505fc72e2b89467910")
assert($toMD5("") == "d41d8cd98f00b204e9800998ecf8427e")
