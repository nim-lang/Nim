discard """
  cmd: "nim doc -r $file"
  errormsg: "Runnable Examples cannot stay behind the actual code"
  line: 10
"""

func big*(integer: int): int =
  ## Constructor for `JsBigInt`.
  when nimvm: doAssert false, "JsBigInt can not be used at compile-time nor static context" else: discard
  runnableExamples:
    doAssert big(1234567890) == big"1234567890"
    doAssert 0b1111100111.big == 0o1747.big and 0o1747.big == 999.big
