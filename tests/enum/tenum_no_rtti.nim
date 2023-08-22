discard """
  output: '''A
B'''
  cmd: '''nim c --gc:arc $file'''
"""
type
  Enum = enum A, B, C
  EnumRange = range[A .. B]
proc test_a(x: Enum): string = $x
proc test_b(x: EnumRange): string = $x
echo test_a(A)
echo test_b(B)
