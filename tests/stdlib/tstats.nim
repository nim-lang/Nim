include stats

proc clean(x: float): float =
  result = round(1.0e8*x).float * 1.0e-8

var rs: RunningStat
rs.push(@[1.0, 2.0, 1.0, 4.0, 1.0, 4.0, 1.0, 2.0])
doAssert(rs.n == 8)
doAssert(clean(rs.mean) == 2.0)
doAssert(clean(rs.variance()) == 1.5)
doAssert(clean(rs.varianceS()) == 1.71428571)
doAssert(clean(rs.skewness()) == 0.81649658)
doAssert(clean(rs.skewnessS()) == 1.01835015)
doAssert(clean(rs.kurtosis()) == -1.0)
doAssert(clean(rs.kurtosisS()) == -0.7000000000000001)

var rs1, rs2: RunningStat
rs1.push(@[1.0, 2.0, 1.0, 4.0])
rs2.push(@[1.0, 4.0, 1.0, 2.0])
let rs3 = rs1 + rs2
doAssert(clean(rs3.mom2) == clean(rs.mom2))
doAssert(clean(rs3.mom3) == clean(rs.mom3))
doAssert(clean(rs3.mom4) == clean(rs.mom4))
rs1 += rs2
doAssert(clean(rs1.mom2) == clean(rs.mom2))
doAssert(clean(rs1.mom3) == clean(rs.mom3))
doAssert(clean(rs1.mom4) == clean(rs.mom4))
rs1.clear()
rs1.push(@[1.0, 2.2, 1.4, 4.9])
doAssert(rs1.sum == 9.5)
doAssert(rs1.mean() == 2.375)

when not defined(cpu32):
  # XXX For some reason on 32bit CPUs these results differ
  var rr: RunningRegress
  rr.push(@[0.0, 1.0, 2.8, 3.0, 4.0], @[0.0, 1.0, 2.3, 3.0, 4.0])
  doAssert(rr.slope() == 0.9695585996955861)
  doAssert(rr.intercept() == -0.03424657534246611)
  doAssert(rr.correlation() == 0.9905100362239381)
  var rr1, rr2: RunningRegress
  rr1.push(@[0.0, 1.0], @[0.0, 1.0])
  rr2.push(@[2.8, 3.0, 4.0], @[2.3, 3.0, 4.0])
  let rr3 = rr1 + rr2
  doAssert(rr3.correlation() == rr.correlation())
  doAssert(clean(rr3.slope()) == clean(rr.slope()))
  doAssert(clean(rr3.intercept()) == clean(rr.intercept()))