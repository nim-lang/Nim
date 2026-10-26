discard """
  matrix: "--parsem:on"
  nimout: '''
hey
hey
hah
hah
'''
"""

# `--parsem:on` variant of tests/generics/tnullary_generics: `static:` blocks in
# routine bodies run when the bodies are checked, after the top-level ones.

# non-generic
proc foo(s: string) =
  static: echo "hah"
  echo s

static: echo "hey"

foo("hoo")

# nullary generic
proc bar[](s: string) =
  static: echo "hah"
  echo s

static: echo "hey"

bar("hoo")
