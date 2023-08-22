discard """
  targets: "cpp"
"""

# bug #2259
type Mat4f* = array[0..15, float]

proc get_rot_mat*(): Mat4f = discard
var mat: Mat4f = get_rot_mat()

# bug #1389
proc calcSizes(): array[2, int] = discard
let sizes: array[2, int] = calcSizes()
