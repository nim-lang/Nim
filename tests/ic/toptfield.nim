discard """
output: '''7'''
"""

# Regression: a generic in the importer reads `r.ttl.get(...)` on a NIF-loaded
# object whose field type is a generic instance (`Opt[uint64]`) with custom
# pragmas. Instantiation goes through another generic that has a parameter
# named `ttl`. nimbus-eth2 failed here with
# "the field 'ttl' is not accessible" / "undeclared field: 'ttl' for type
# protobuf.Register" because reclist fields were loaded as flagless stubs.

import moptfield

let r = Register(ns: "", ttl: some(7'u64))
echo advertise(r, some(1'u64), 0)
