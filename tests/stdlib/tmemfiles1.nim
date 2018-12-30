import memfiles, os
var
  mm: MemFile
  fn = "test.mmap"
# Create a new file
mm = memfiles.open(fn, mode = fmReadWrite, newFileSize = 20)
mm.close()
# mm.close()
if fileExists(fn): removeFile(fn)
