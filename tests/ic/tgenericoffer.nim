discard """
output: '''200'''
"""

# Regression test for the `(offer …)` generic-instance sharing across the NIF
# boundary. A generic loaded from a NIF whose body uses a type-bound op on a
# CONCRETE type (here getOrDefault on Table[MultiCodec,int]) must be reused, not
# re-instantiated in the consumer's scope which lacks the type's `==`. Before the
# fix this failed under `nim ic` with `hashcommon.nim type mismatch ... MultiCodec`.

import mgofpid
echo callDigest()
