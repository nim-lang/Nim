discard """
output: '''
true
true
'''
"""

# bug #26401

import std/macros

template marker() {.pragma.}

type
  Base[T] = object
    field {.marker.}: T

  Alias = Base[int]

echo Base[int]().field.hasCustomPragma(marker)
echo Alias().field.hasCustomPragma(marker)
