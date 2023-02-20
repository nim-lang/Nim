discard """
  disabled: "Windows"
  output: '''Full read size: 20
Half read size: 10 Data: Hello'''
"""
import memfiles, os
const
  fn = "test.mmap"
var
  mm, mm_full, mm_half: MemFile
  p: pointer

if fileExists(fn): removeFile(fn)

# Create a new file, data all zeros, starting at size 10
mm = memfiles.open(fn, mode = fmReadWrite, newFileSize = 10, allowRemap=true)
mm.resize 20  # resize up to 20
mm.close()

# read, change
mm_full = memfiles.open(fn, mode = fmWrite, mappedSize = -1, allowRemap = true)
let size = mm_full.size
p = mm_full.mapMem(fmReadWrite, 20, 0)
echo "Full read size: ", size
var p2 = cast[cstring](p)
p2[0] = 'H'
p2[1] = 'e'
p2[2] = 'l'
p2[3] = 'l'
p2[4] = 'o'
p2[5] = '\0'
mm_full.unmapMem(p, 20)
mm_full.close()

# read half, and verify data change
mm_half = memfiles.open(fn, mode = fmRead, mappedSize = 10)
echo "Half read size: ", mm_half.size, " Data: ", cast[cstring](mm_half.mem)
mm_half.close()

if fileExists(fn): removeFile(fn)
