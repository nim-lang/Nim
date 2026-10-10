discard """
  output: "42"
"""

# A package found only via `nimblepath` (see nim.cfg): the IC
# driver replays the precompiled config and must still see the nimble dirs.

import fakepkg

echo fakeAnswer()
