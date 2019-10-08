discard """
  output: '''ÄhmÖÜ
abasdfdsmÄhmaИ
Иnastystring
A你好
ИnastystringA你好
ÖÜhmabasdfdsmÄhmaИOK'''
  disabled: "posix"
  joinable: "false"
"""

import winlean

echo "ÄhmÖÜ"
echo "abasdfdsmÄhmaИ"
echo "Иnastystring"
echo "A你好"

write stdout, "Иnastystring"
writeLine stdout, "A你好"
stdout.flushFile()

let handle = getOsFileHandle(stdout)
var a = "ÖÜhmabasdfdsmÄhmaИ"
var ac = 0'i32
discard writeFile(handle, addr a[0], int32(len(a)), addr ac, nil)
stdout.flushFile()

import os

let str = "some nulls: \0\0\0 (three of them)"

let fpath = getTempDir() / "file_with_nulls.bin"

writeFile(fpath, str)

doAssert(getFileSize(fpath) == 31)
doAssert(readFile(fpath) == str)
removeFile(fpath)

echo "OK"
