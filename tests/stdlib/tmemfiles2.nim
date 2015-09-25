discard """
  test creating/reading/writing/changing memfiles
  file: "tmemfiles2.nim"
  output: '''Full read size: 20
Half read size: 10 Data: Hello'''
"""
import memfiles, os
var
  mm, mm_full, mm_half: MemFile
  fn = "test.mmap"
  p: pointer

if fileExists(fn): removeFile(fn)

# Create a new file, data all zeros
mm = memfiles.open(fn, mode = fmReadWrite, newFileSize = 20)
mm.close()

# read, change
mm_full = memfiles.open(fn, mode = fmWrite, mappedSize = -1)
echo "Full read size: ",mm_full.size
p = mm_full.mapMem(fmReadWrite, 20, 0)
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
echo "Half read size: ",mm_half.size, " Data: ", cast[cstring](mm_half.mem)
mm_half.close()

if fileExists(fn): removeFile(fn)
