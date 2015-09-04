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
