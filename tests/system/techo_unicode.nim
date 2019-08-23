discard """
  output: '''ÄhmÖÜ
abasdfdsmÄhmaИ
Иnastystring
A你好
ИnastystringA你好
ÖÜhmabasdfdsmÄhmaИ'''
  disabled: "posix"
  joinable: "false"
"""

import winlean

echo "ÄhmÖÜ"
echo "abasdfdsmÄhmaИ"
echo "И\0nasty\0\0\0\0string\0"
echo "A你好"

write stdout, "И\0nasty\0\0\0\0string\0"
writeLine stdout, "A你好"
stdout.flushFile()

let handle = getOsFileHandle(stdout)
var a = "ÖÜhmabasdfdsmÄhmaИ"
var ac = 0'i32
discard writeFile(handle, addr a[0], int32(len(a)), addr ac, nil)
stdout.flushFile()
