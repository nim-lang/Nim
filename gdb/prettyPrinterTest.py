import gdb
# this test should test the gdb pretty printers of the nim
# library. But be aware this test is not complete. It only tests the
# command line version of gdb. It does not test anything for the
# machine interface of gdb. This means if if this test passes gdb
# frontends might still be broken.

gdb.execute("source ../tools/nim-gdb.py")
# debug all instances of the generic function `myDebug`, should be 8
gdb.execute("rbreak myDebug")
gdb.execute("run")

outputs = [
  'meTwo',
  '"meTwo"',
  '{meOne, meThree}',
  'MyOtherEnum(1)',
  '5',
  '0x7fffffffe190',
  'seq(3, 3) = {"one", "two", "three"}',
  'Table(3, 64) = {["two"] = 2, ["three"] = 3, ["one"] = 1}',
]

for expected in outputs:
  output = str(gdb.parse_and_eval("arg"))
  assert output == expected, output + " != " + expected
  gdb.execute("continue")
