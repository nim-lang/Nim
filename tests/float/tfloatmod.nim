discard """
  targets: "c cpp js"
  output: "ok"
  exitcode: "0"
"""

# Test `mod` on float64 both at compiletime and at runtime
import math

# Testdata from golang
const testValues: array[10, tuple[f64, expected: float64]] = [
  (4.9790119248836735e+00, 4.197615023265299782906368e-02),
  (7.7388724745781045e+00, 2.261127525421895434476482e+00),
  (-2.7688005719200159e-01, 3.231794108794261433104108e-02),
  (-5.0106036182710749e+00, 4.989396381728925078391512e+00),
  (9.6362937071984173e+00, 3.637062928015826201999516e-01),
  (2.9263772392439646e+00, 1.220868282268106064236690e+00),
  (5.2290834314593066e+00, 4.770916568540693347699744e+00),
  (2.7279399104360102e+00, 1.816180268691969246219742e+00),
  (1.8253080916808550e+00, 8.734595415957246977711748e-01),
  (-8.6859247685756013e+00, 1.314075231424398637614104e+00)]

const simpleTestData = [
  (5.0, 3.0, 2.0),
  (5.0, -3.0, 2.0),
  (-5.0, 3.0, -2.0),
  (-5.0, -3.0, -2.0),
  (10.0, 1.0, 0.0),
  (10.0, 0.5, 0.0),
  (10.0, 1.5, 1.0),
  (-10.0, 1.0, -0.0),
  (-10.0, 0.5, -0.0),
  (-10.0, 1.5, -1.0),
  (1.5, 1.0, 0.5),
  (1.25, 1.0, 0.25),
  (1.125, 1.0, 0.125)
  ]

const specialCases = [
  (-Inf, -Inf, Nan),
  (-Inf, -Pi, Nan),
  (-Inf, 0.0, Nan),
  (-Inf, Pi, Nan),
  (-Inf, Inf, Nan),
  (-Inf, Nan, Nan),
  (-PI, -Inf, -PI),
  (-PI, 0.0, Nan),
  (-PI, Inf, -PI),
  (-PI, Nan, Nan),
  (-0.0, -Inf, -0.0),
  (-0.0, 0.0, Nan),
  (-0.0, Inf, -0.0),
  (-0.0, Nan, Nan),
  (0.0, -Inf, 0.0),
  (0.0, 0.0, Nan),
  (0.0, Inf, 0.0),
  (0.0, Nan, Nan),
  (PI, -Inf, PI),
  (PI, 0.0, Nan),
  (PI, Inf, PI),
  (PI, Nan, Nan),
  (Inf, -Inf, Nan),
  (Inf, -PI, Nan),
  (Inf, 0.0, Nan),
  (Inf, PI, Nan),
  (Inf, Inf, Nan),
  (Inf, Nan, Nan),
  (Nan, -Inf, Nan),
  (Nan, -PI, Nan),
  (Nan, 0.0, Nan),
  (Nan, PI, Nan),
  (Nan, Inf, Nan),
  (Nan, Nan, Nan)]

const extremeValues = [
  (5.9790119248836734e+200, 1.1258465975523544, 0.6447968302508578),
  (1.0e-100, 1.0e100, 1.0e-100)]

proc errmsg(x, y, r, expected: float64): string =
  $x & " mod " & $y & " == " & $r & " but expected " & $expected

proc golangtest() =
  let x = 10.0
  for tpl in testValues:
    let (y, expected) = tpl
    let r = x mod y
    doAssert(r == expected, errmsg(x, y, r, expected))

proc simpletest() =
  for tpl in simpleTestData:
    let(x, y, expected) = tpl
    let r = x mod y
    doAssert(r == expected, errmsg(x, y, r, expected))

proc testSpecialCases() =
  proc isnan(f: float64): bool =
    case classify(f)
    of fcNan:
      result = true
    else:
      result = false

  for tpl in specialCases:
    let(x, y, expected) = tpl
    let r = x mod y
    doAssert((r == expected) or (r.isnan and expected.isnan),
              errmsg(x, y, r, expected))

proc testExtremeValues() =
  for tpl in extremeValues:
    let (x, y, expected) = tpl
    let r = x mod y
    doAssert(r == expected, errmsg(x, y, r, expected))

static:
  # compiletime evaluation
  golangtest()
  simpletest()
  testSpecialCases()
  testExtremeValues()

proc main() =
  # runtime evaluation
  golangtest()
  simpletest()
  testSpecialCases()
  testExtremeValues()

main()
echo "ok"
