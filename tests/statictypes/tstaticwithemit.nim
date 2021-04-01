discard """
  output: "Hello, Nim"
"""

proc printStr[N: static string]() =
  {.emit: """puts("`N`");""" .}
printStr["Hello, Nim"]()
