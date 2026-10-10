discard """
  targets: "cpp"
  matrix: "--mm:arc; --mm:orc; --mm:refc"
  output: '''
finally
after
'''
"""

# Regression test: typeless `except:` followed by `finally:` must not
# trigger ReraiseDefect at the end of the proc.
#
# Previously, `genTryCpp` only emitted `T_ = nullptr;` in the *typed*
# except branches, leaving the typeless `except:` path with a still-set
# `T_`.  After the handler body and `popCurrentException`, the trailing
# `if (T_) std::rethrow_exception(T_);` in the finally block would still
# fire — but with the Nim exception stack already popped, the rethrow
# bubbled up as a `ReraiseDefect: no exception to reraise`.

proc test() =
  try:
    raise newException(CatchableError, "x")
  except:
    let e = getCurrentException()
    discard e
  finally:
    echo "finally"

test()
echo "after"
