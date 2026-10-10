discard """
  action: compile
"""

# bug #25474
type Bug = array[0..1, array[0..5, array[0..63, array[0..1, array[0..5,
  array[0..63, array[7282, byte]]]]]]]

static: doAssert sizeof(Bug) == 2 * 6 * 64 * 2 * 6 * 64 * 7282
