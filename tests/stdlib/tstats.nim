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

block:
  var 
    a4 = [6, 3, 9, 1]
    a5 = [4, 6, 3, 9, 1]
    a: array[len(a4), int]
    ax: array[len(a5), int]

  func myCmp(x,y:int):int =
    if x==y : 0 elif x<y : -1 else: 1

  a= a4
  doAssert quickSelect(a, 0, len(a4)-1, 0, myCmp) == 1  # smallest element
  a= a4
  doAssert quickSelect(a, 0, len(a4)-1, len(a4)-1, myCmp) == 9  # largest element
  #
  a= a4
  doAssert median(a,myCmp) == 4.5
  a= a4
  doAssert median(a,mdlow,myCmp) == 3
  a= a4
  doAssert median(a,mdhigh,myCmp) == 6
  #
  ax= a5
  doAssert median(ax,myCmp) == 4.0
  ax= a5
  doAssert median(ax,mdlow,myCmp) == 4
  ax= a5
  doAssert median(ax,mdhigh,myCmp) == 4

  func fltCmp(x,y:float):int =
    if x==y : 0
    elif x<y : -1
    else     : 1

  var  f = [7.0,4.0,6.0,3.0,9.0,1.0]

  doAssert median(f,fltCmp) == 5.0

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
