import gdb
import re
import sys
# this test should test the gdb pretty printers of the nim
# library. But be aware this test is not complete. It only tests the
# command line version of gdb. It does not test anything for the
# machine interface of gdb. This means if if this test passes gdb
# frontends might still be broken.

gdb.execute("set python print-stack full")
gdb.execute("source ../../../tools/debug/nim-gdb.py")
# debug all instances of the generic function `myDebug`, should be 14
gdb.execute("rbreak myDebug")
gdb.execute("run")

outputs = [
  'meTwo',
  '""',
  '"meTwo"',
  '{meOne, meThree}',
  'MyOtherEnum(1)',
  '{MyOtherEnum(0), MyOtherEnum(2)}',
  'array = {1, 2, 3, 4, 5}',
  'seq(0, 0)',
  'seq(0, 10)',
  'array = {"one", "two"}',
  'seq(3, 3) = {1, 2, 3}',
  'seq(3, 3) = {"one", "two", "three"}',
  'Table(3, 64) = {[4] = "four", [5] = "five", [6] = "six"}',
  'Table(3, 8) = {["two"] = 2, ["three"] = 3, ["one"] = 1}',
  '{a = 1, b = "some string"}',
  '("hello", 42)'
]

argRegex = re.compile("^.* = (?:No suitable Nim \$ operator found for type: \w+\s*)*(.*)$")
# Remove this error message which can pop up
noSuitableRegex = re.compile("(No suitable Nim \$ operator found for type: \w+\s*)")

for i, expected in enumerate(outputs):
  gdb.write(f"\x1b[38;5;105m{i+1}) expecting: {expected}: \x1b[0m", gdb.STDLOG)
  gdb.flush()
  currFrame = gdb.selected_frame()
  functionSymbol = currFrame.block().function
  assert functionSymbol.line == 24, str(functionSymbol.line)
  raw = ""
  if i == 6:
    # myArray is passed as pointer to int to myDebug. I look up myArray up in the stack
    gdb.execute("up")
    raw = gdb.parse_and_eval("myArray")    
  elif i == 9:
    # myOtherArray is passed as pointer to int to myDebug. I look up myOtherArray up in the stack
    gdb.execute("up")
    raw = gdb.parse_and_eval("myOtherArray")
  else:
    rawArg = re.sub(noSuitableRegex, "", gdb.execute("info args", to_string = True))
    raw = rawArg.split("=", 1)[-1].strip()
  output = str(raw)

  if output != expected:
    gdb.write(f"\x1b[38;5;196m ({output}) != expected: ({expected})\x1b[0m\n", gdb.STDERR)
    gdb.execute("quit 1")
  else:
    gdb.write("\x1b[38;5;34mpassed\x1b[0m\n", gdb.STDLOG)
  gdb.execute("continue")
