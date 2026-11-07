discard """
  joinable: false
  output: '''
2 3
3
'''
"""

# `import m as alias {.cyclic.}` is `import m {.cyclic.} as alias`, and the
# same holds for `{.all.}`:
import forms/mimport_as as ma {.cyclic.}
import forms/sub/[mimport_as2 as ma2 {.cyclic.}]

proc fa*(): int = 1

echo ma.fb(), " ", ma2.fc()
echo ma.hiddenB()
