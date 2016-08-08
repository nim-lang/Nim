discard """
  file: "tlistcomprehensions.nim"
  exitcode: 0
"""

const n = 20

let
  evens = lc[x | (x <- 1..10, x mod 2 == 0), int]
  rightTriangles = lc[
    (x, y, z) | (x <- 1..n, y <- x..n, z <- y..n, x*x + y*y == z*z),
    tuple[a, b, c: int]
  ]

doAssert evens == @[2, 4, 6, 8, 10]
doAssert rightTriangles == @[
  (a: 3, b: 4, c: 5),
  (a: 5, b: 12, c: 13),
  (a: 6, b: 8, c: 10),
  (a: 8, b: 15, c: 17),
  (a: 9, b: 12, c: 15),
  (a: 12, b: 16, c: 20)
]
