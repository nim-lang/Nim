discard """
  joinable: false
  output: '''
23 10
22 20
'''
"""

# `import m {.cyclic.} except x` and `import dir/[a {.cyclic.}, b {.cyclic.}]`
import forms/sub/[mforms_b {.cyclic.}, mforms_c {.cyclic.} as cc]
import forms/mforms_except {.cyclic.} except hidden

proc fa*(): int = 1
proc hidden*(): int = 10

echo fb(), cc.fc(), " ", hidden()
echo fe(), " ", mforms_except.hidden()
