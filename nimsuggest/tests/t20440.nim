when not defined(js):
  {.fatal: "Crash".}
echo 4

discard """
$nimsuggest --v3 --tester $file
"""
