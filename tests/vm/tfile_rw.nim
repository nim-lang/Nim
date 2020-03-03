discard """
  output: '''ok'''
"""

# test file read write in vm

import os, strutils

const filename  = splitFile(currentSourcePath).dir / "tfile_rw.txt"

const mytext = "line1\nline2\nline3"
static:
  writeFile(filename, mytext)
const myfile_str = staticRead(filename)
const myfile_str2 = readFile(filename)
const myfile_str_seq = readLines(filename, 3)

static:
  doAssert myfile_str == mytext
  doAssert myfile_str2 == mytext
  doAssert myfile_str_seq[0] == "line1"
  doAssert myfile_str_seq[1] == "line2"
  doAssert myfile_str_seq.join("\n") == mytext


removeFile(filename)
echo "ok"