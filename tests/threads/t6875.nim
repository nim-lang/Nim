discard """
  matrix: "--threads"
  joinable: false
"""

# bug #6875
proc testCreateThread(): Thread[int] =
  createThread(result, proc(a: int) = discard, 0)

let t = testCreateThread()
t.joinThread()
