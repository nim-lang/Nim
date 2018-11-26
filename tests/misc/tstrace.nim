discard """
exitcode: 1
output: '''
Traceback (most recent call last)
tstrace.nim(36)          tstrace
tstrace.nim(28)          recTest
tstrace.nim(28)          recTest
tstrace.nim(28)          recTest
tstrace.nim(28)          recTest
tstrace.nim(28)          recTest
tstrace.nim(28)          recTest
tstrace.nim(28)          recTest
tstrace.nim(28)          recTest
tstrace.nim(28)          recTest
tstrace.nim(28)          recTest
tstrace.nim(31)          recTest
SIGSEGV: Illegal storage access. (Attempt to read from nil?)
'''
"""

# Test the new stacktraces (great for debugging!)

{.push stack_trace: on.}

proc recTest(i: int) =
  # enter
  if i < 10:
    recTest(i+1)
  else: # should printStackTrace()
    var p: ptr int = nil
    p[] = 12
  # leave

{.pop.}

recTest(0)
