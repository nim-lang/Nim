import gdb
# this test should test the gdb pretty printers of the nim
# library. But be aware this test is not complete. It only tests the
# command line version of gdb. It does not test anything for the
# machine interface of gdb. This means if if this test passes gdb
# frontends might still be broken.

gdb.execute("source ../../../tools/nim-gdb.py")
# debug all instances of the generic function `myDebug`, should be 8
gdb.execute("rbreak myDebug")
gdb.execute("run")

outputs = [
  'meTwo',
  '"meTwo"',
  '{meOne, meThree}',
  'MyOtherEnum(1)',
  '5',
  'array = {1, 2, 3, 4, 5}',
  'seq(3, 3) = {"one", "two", "three"}',
  'Table(3, 64) = {["two"] = 2, ["three"] = 3, ["one"] = 1}',
]

for i, expected in enumerate(outputs):
  functionSymbol = gdb.selected_frame().block().function
  assert functionSymbol.line == 21

  if i == 5:
    # myArray is passed as pointer to int to myDebug. I look up myArray up in the stack
    gdb.execute("up")
    output = str(gdb.parse_and_eval("myArray"))
  else:
    output = str(gdb.parse_and_eval("arg"))

  assert output == expected, output + " != " + expected
  gdb.execute("continue")
