discard """
  output: '''true
true
true
true
true
true
true
true
true
All:
__really_obscure_dir_name/are.x
__really_obscure_dir_name/created
__really_obscure_dir_name/dirs
__really_obscure_dir_name/files.q
__really_obscure_dir_name/some
__really_obscure_dir_name/test
__really_obscure_dir_name/testing.r
__really_obscure_dir_name/these.txt
Files:
__really_obscure_dir_name/are.x
__really_obscure_dir_name/files.q
__really_obscure_dir_name/testing.r
__really_obscure_dir_name/these.txt
Dirs:
__really_obscure_dir_name/created
__really_obscure_dir_name/dirs
__really_obscure_dir_name/some
__really_obscure_dir_name/test
false
false
false
false
false
false
false
false
false
true
true
Raises
'''
"""
# test os path creation, iteration, and deletion

import os, strutils

let files = @["these.txt", "are.x", "testing.r", "files.q"]
let dirs = @["some", "created", "test", "dirs"]

let dname = "__really_obscure_dir_name"

createDir(dname)
echo dirExists(dname)

# Test creating files and dirs
for dir in dirs:
  createDir(dname/dir)
  echo dirExists(dname/dir)

for file in files:
  let fh = open(dname/file, fmReadWrite)
  fh.close()
  echo fileExists(dname/file)

echo "All:"

template norm(x): untyped =
  (when defined(windows): x.replace('\\', '/') else: x)

for path in walkPattern(dname/"*"):
  echo path.norm

echo "Files:"

for path in walkFiles(dname/"*"):
  echo path.norm

echo "Dirs:"

for path in walkDirs(dname/"*"):
  echo path.norm

# Test removal of files dirs
for dir in dirs:
  removeDir(dname/dir)
  echo dirExists(dname/dir)

for file in files:
  removeFile(dname/file)
  echo fileExists(dname/file)

removeDir(dname)
echo dirExists(dname)

# createDir should create recursive directories
createDir(dirs[0] / dirs[1])
echo dirExists(dirs[0] / dirs[1]) # true
removeDir(dirs[0])

# createDir should properly handle trailing separator
createDir(dname / "")
echo dirExists(dname) # true
removeDir(dname)

# createDir should raise IOError if the path exists
# and is not a directory
open(dname, fmWrite).close
try:
  createDir(dname)
except IOError:
  echo "Raises"
removeFile(dname)
