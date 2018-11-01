template echoToResult*(args: varargs[string, `$`]): untyped =
  ## in tests, replace ``echo a, b, c`` by ``echoToResult a, b, c`` and 
  ## ``proc mytest()`` to ``proc mytest(): string``
  for a in args:
    result.add $a
  result.add "\n"
