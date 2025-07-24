
type
  Grid2D*[I: SomeInteger, w, h: static[I], T] = object
    grid: array[w, array[h, T]]
  Grid2DIns = Grid2D[int, 2, 3, uint8]

let a = Grid2DIns()
doAssert a.grid.len == 2
doAssert a.grid[0].len == 3
