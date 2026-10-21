discard """
output: '''3
0'''
"""

# bug #26489: `type FlatType = seq[byte]` inside `check` makes `FlatType` the
# `sym` of `Envelope.payload`'s type. Writing that sym while inside Envelope's
# reclist also wrote `check`'s body, whose `value.signature` claimed the field
# def, so Envelope's own `signature` entry became an owner-less stub on load.

import mfieldreclistalias

let e = Envelope(signature: 3)
echo e.signature
echo run()
