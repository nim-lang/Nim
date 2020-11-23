import random

proc main =
  var occur: array[1000, int]

  var x = 8234
  for i in 0..100_000:
    x = rand(high(occur))
    inc occur[x]
  for i, oc in occur:
    if oc < 69:
      doAssert false, "too few occurrences of " & $i
    elif oc > 150:
      doAssert false, "too many occurrences of " & $i

  when false:
    var rs: RunningStat
    for j in 1..5:
      for i in 1 .. 1_000:
        rs.push(gauss())
      echo("mean: ", rs.mean,
        " stdDev: ", rs.standardDeviation(),
        " min: ", rs.min,
        " max: ", rs.max)
      rs.clear()

  var a = [0, 1]
  shuffle(a)
  doAssert a[0] == 1
  doAssert a[1] == 0

  doAssert rand(0) == 0
  doAssert sample("a") == 'a'

  when compileOption("rangeChecks"):
    try:
      discard rand(-1)
      doAssert false
    except RangeDefect:
      discard

    try:
      discard rand(-1.0)
      doAssert false
    except RangeDefect:
      discard


  # don't use causes integer overflow
  doAssert compiles(rand[int](low(int) .. high(int)))

randomize(223)
main()
