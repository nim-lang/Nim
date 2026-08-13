discard """
output: '''hi'''
"""

# Regression: NIF-loaded nested proc whose body is a bare assignment, walked by
# `injectDestructorCalls` / `getPotentialWrites` because the outer routine has a
# sink parameter. nimbus-eth2 `nim ic` crashed with
# "index out of bounds, the container is empty [IndexDefect]" in trees.nim.

import mnestasgn
consume("hi")
