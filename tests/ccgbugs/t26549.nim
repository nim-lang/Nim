discard """
  matrix: "--mm:refc; --mm:orc"
  targets: "c"
  ccodecheck: "\\i !@'NIM_NIL)->'"
  output: '''
0
0'''
"""

# bug #26549: passing "" to an openArray produced `nil->data` which clang's
# UBSan reports even though it is never evaluated

proc f(a: openArray[char]): int = a.len

echo f("")
echo f(['a'].toOpenArray(1, 0))
