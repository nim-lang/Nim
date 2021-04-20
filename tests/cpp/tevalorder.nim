discard """
  output: '''0
1
2'''
targets: "cpp"
"""

# bug #8202
var current: int = 0

proc gen(): string = current.inc; $(current - 1)

proc allOut(a, b, c: string) =
    echo a
    echo b
    echo c

allOut(gen(), gen(), gen())
