discard """
  targets: "c js cpp"
"""

# tests `getStacktrace`

const vm = """
stack trace: (most recent call last)
tproper_stacktrace4.nim(43, 14) tproper_stacktrace4
tproper_stacktrace4.nim(42, 19) fn3
tproper_stacktrace4.nim(41, 18) fn2
tproper_stacktrace4.nim(33, 26) fn"""

const js = """
Traceback (most recent call last)
tproper_stacktrace4.nim(44) at module tproper_stacktrace4
tproper_stacktrace4.nim(42) at tproper_stacktrace4.fn3
tproper_stacktrace4.nim(41) at tproper_stacktrace4.fn2
tproper_stacktrace4.nim(33) at tproper_stacktrace4.fn
"""

const c = """
Traceback (most recent call last)
tproper_stacktrace4.nim(44) tproper_stacktrace4
tproper_stacktrace4.nim(42) fn3
tproper_stacktrace4.nim(41) fn2
tproper_stacktrace4.nim(33) fn
"""

# line 30
when true:
  proc fn()=
    let s = getStacktrace()
    when nimvm:
      doAssert s == vm, "\n" & s
    else:
      when defined(js):
        doAssert s == js, "\n" & s
      else:
        doAssert s == c, "\n" & s
  proc fn2() = fn()
  proc fn3() = fn2()
  static: fn3()
  fn3()
