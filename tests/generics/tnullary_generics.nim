discard """
  nimout: '''
hah
hey
hey
hah
'''
"""

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
