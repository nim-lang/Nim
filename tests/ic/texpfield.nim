discard """
output: '''7'''
"""

# Regression: a generic in the importer reads an *exported* field of a
# NIF-loaded object type. nimbus-eth2 failed here with
# "undeclared field: 'ttl' for type protobuf.Register" while instantiating
# a generic (`save`) under `nim ic`.

import mexpfield

proc use*[T](r: Rec, x: T): int = r.ttl + x

echo use(makeRec(3), 4)
