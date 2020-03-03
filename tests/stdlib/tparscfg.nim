discard """
output: '''
utf-8
on
hello
lihf8515
10214028
lihaifeng@wxm.com
===
charset=utf-8
[Package]
name=hello
--threads:on
[Author]
name=lhf
qq=10214028
email="lihaifeng@wxm.com"
===
charset=utf-8
[Package]
name=hello
--threads:on
[Author]
name=lihf8515
qq=10214028
'''
"""
import parsecfg, streams

## Creating a configuration file.
var dict1=newConfig()
dict1.setSectionKey("","charset","utf-8")
dict1.setSectionKey("Package","name","hello")
dict1.setSectionKey("Package","--threads","on")
dict1.setSectionKey("Author","name","lihf8515")
dict1.setSectionKey("Author","qq","10214028")
dict1.setSectionKey("Author","email","lihaifeng@wxm.com")
var ss = newStringStream()
dict1.writeConfig(ss)

## Reading a configuration file.
var dict2 = loadConfig(newStringStream(ss.data))
var charset = dict2.getSectionValue("","charset")
var threads = dict2.getSectionValue("Package","--threads")
var pname = dict2.getSectionValue("Package","name")
var name = dict2.getSectionValue("Author","name")
var qq = dict2.getSectionValue("Author","qq")
var email = dict2.getSectionValue("Author","email")
echo charset
echo threads
echo pname
echo name
echo qq
echo email

echo "==="

## Modifying a configuration file.
var dict3 = loadConfig(newStringStream(ss.data))
dict3.setSectionKey("Author","name","lhf")
write(stdout, $dict3)

echo "==="

## Deleting a section key in a configuration file.
var dict4 = loadConfig(newStringStream(ss.data))
dict4.delSectionKey("Author","email")
write(stdout, $dict4)

