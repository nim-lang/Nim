discard """
  output: "OK"
"""
import os

let str = "some nulls: \0\0\0 (three of them)"

let fpath = getTempDir() / "file_with_nulls.bin"

writeFile(fpath, str)

doAssert(getFileSize(fpath) == 31)
doAssert(readFile(fpath) == str)

echo "OK"