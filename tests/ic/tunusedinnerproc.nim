discard """
  output: '''1
2
3'''
"""

# bug #26742: IC serializes an inner proc's definition as a bare symbol
# statement. cg must not generate an unused inner proc there: lambda lifting
# leaves it untransformed, so its body still reads `theme` directly although
# `theme` lives in the closure environment ("expr: var not init theme").

(proc () =
  var theme = 0
  proc lit(): int = theme
  var cb = proc (): int = theme)()

proc outer() =
  var x = 1
  proc unused(): int = x
  proc used(): int = x + 1
  proc plain(a: int): int = a + 2
  let cb = proc (): int = x
  echo cb()
  echo used()
  echo plain(1)

outer()
