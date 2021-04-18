import gdb
# this test should test the gdb pretty printers of the nim
# library. But be aware this test is not complete. It only tests the
# command line version of gdb. It does not test anything for the
# machine interface of gdb. This means if if this test passes gdb
# frontends might still be broken.

gdb.execute("source ../../../tools/nim-gdb.py")
# debug all instances of the generic function `myDebug`, should be 14
gdb.execute("rbreak myDebug")
gdb.execute("run")

outputs = [
  'meTwo',
  '""',
  '"meTwo"',
  '{meOne, meThree}',
  'MyOtherEnum(1)',
  '5',
  'array = {1, 2, 3, 4, 5}',
  'seq(0, 0)',
  'seq(0, 10)',
  'array = {"one", "two"}',
  'seq(3, 3) = {1, 2, 3}',
  'seq(3, 3) = {"one", "two", "three"}',
  'Table(3, 64) = {[4] = "four", [5] = "five", [6] = "six"}',
  'Table(3, 8) = {["two"] = 2, ["three"] = 3, ["one"] = 1}',
  '{a = 1, b = "some string"}'
]

for i, expected in enumerate(outputs):
  gdb.write(f"{i+1}) expecting: {expected}: ", gdb.STDLOG)
  gdb.flush()

  functionSymbol = gdb.selected_frame().block().function
  assert functionSymbol.line == 41, str(functionSymbol.line)

  if i == 6:
    # myArray is passed as pointer to int to myDebug. I look up myArray up in the stack
    gdb.execute("up")
    raw = gdb.parse_and_eval("myArray")    
  elif i == 9:
    # myOtherArray is passed as pointer to int to myDebug. I look up myOtherArray up in the stack
    gdb.execute("up")
    raw = gdb.parse_and_eval("myOtherArray")
  else:
    raw = gdb.parse_and_eval("arg")

  output = str(raw)

  assert output == expected, "{0} : output: ({1}) != expected: ({2})".format(i, output, expected)
  gdb.write(f"passed\n", gdb.STDLOG)
  gdb.execute("continue")
