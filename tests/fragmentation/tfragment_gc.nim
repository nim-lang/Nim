


#include system/ansi_c

import strutils, data

proc main =
  var m = 0
  for i in 0..1000_000:
    let size = sizes[i mod sizes.len]
    let p = newString(size)
 #   c_fprintf(stdout, "iteration: %ld size: %ld\n", i, size)

main()
echo formatSize getOccupiedMem(), " / ", formatSize getTotalMem()
