discard """
  targets: "c c++ js"
  output: "ok"
"""

import strutils

var tdata = @[(f: -5.7123456789e-119, expected: "-5.712e-119", prec: 4),
              (f: 0.000124356, expected: "0.0001243560000000000", prec: -2),
              (f: 0.000124356, expected: "0.000124356", prec: -1),
              (f: 0.000124356, expected: "0.0001", prec: 0),
              (f: 0.000554356, expected: "0.0006", prec: 1),
              (f: 0.000144999, expected: "0.0001", prec: 1),
              (f: 0.000124356, expected: "0.00012436", prec: 5),
              (f: 0.000124356, expected: "0.0001243560", prec: 7),
              (f: 1e23, expected: "1.0e+23", prec: 2),
              ]
              
proc test(tdata: seq[tuple[f: float, expected: string, prec: int]]) =
  for d in tdata:
    var ds: string
    if d.prec < -1:
      ds = formatBiggestFloat(d.f, ffDefault)
    else:
      ds = formatBiggestFloat(d.f, ffDefault, d.prec)
    doAssert ds == d.expected, ds & " != " & d.expected
    
test(tdata)
echo "ok"