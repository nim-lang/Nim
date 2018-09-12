discard """
  targets: "c c++ js"
  output: '''ok
1.0'''
"""

static:
  const a = float(uint(1))
  doAssert a == 1.0
  var b: float = 1.0
  doAssert a + b == 2.0

static:
  let a = float(uint(1))
  doAssert a == 1.0

static:
  var a = float(uint(1))
  doAssert a == 1.0

proc test() =
  doAssert float(uint16(1)) == 1.0
  const a = float(uint16(1))
  doAssert a == 1.0
  let b = float(uint16(1))
  doAssert b == 1.0
  var c = float(uint16(1))
  doAssert c == 1.0
  echo "ok"
test()

echo 1 * float(uint16(1))