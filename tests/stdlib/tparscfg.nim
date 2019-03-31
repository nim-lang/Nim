discard """
output: '''
utf-8
on
hello
lihf8515
10214028
lihaifeng@wxm.com
===
charset="utf-8"
[Package]
name="hello"
--threads:"on"
[Author]
name="lhf"
qq="10214028"
email="lihaifeng@wxm.com"
===
charset="utf-8"
[Package]
name="hello"
--threads:"on"
[Author]
name="lihf8515"
qq="10214028"
'''
"""
import parsecfg, streams

## Creating a configuration file.
var dict1=newConfig()
dict1.set("","charset","utf-8")
dict1.set("Package","name","hello")
dict1.set("Package","--threads","on")
dict1.set("Author","name","lihf8515")
dict1.set("Author","qq","10214028")
dict1.set("Author","email","lihaifeng@wxm.com")
var ss = newStringStream()
dict1.write(ss)

## Reading a configuration file.
var dict2 = loadConfig(newStringStream(ss.data))
var charset = dict2.get("","charset")
var threads = dict2.get("Package","--threads")
var pname = dict2.get("Package","name")
var name = dict2.get("Author","name")
var qq = dict2.get("Author","qq")
var email = dict2.get("Author","email")
echo charset
echo threads
echo pname
echo name
echo qq
echo email

echo "==="

## Modifying a configuration file.
var dict3 = loadConfig(newStringStream(ss.data))
dict3.set("Author","name","lhf")
write(stdout, $dict3)

echo "==="

## Deleting a section key in a configuration file.
var dict4 = loadConfig(newStringStream(ss.data))
dict4.del("Author","email")
write(stdout, $dict4)

