discard """
  output: '''ÄhmÖÜ
abasdfdsmÄhmaИ
Иnastystring
A你好
ИnastystringA你好'''
  disabled: "posix"
"""

echo "ÄhmÖÜ"
echo "abasdfdsmÄhmaИ"
stdout.flushFile()
echo "И\0nasty\0\0\0\0string\0"
echo "A你好"

write stdout, "И\0nasty\0\0\0\0string\0"
writeLine stdout, "A你好"
