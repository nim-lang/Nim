discard """
output: '''7'''
"""

# Regression test for the nimbus-eth2 `nim ic` SIGSEGV in `sameModules` /
# `fieldVisible`: instantiating a generic that constructs an object with
# *private* fields (and then reads them back via nested field access) from
# another module. The producer is loaded from NIF, so the field's owner chain
# and the friend-module identity must survive the load.

import mprivfield
echo getHidden(makeRec(7))
