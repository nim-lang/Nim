discard """
  output: '''OK'''
"""

#bug #6046
import parsecfg

var config = newConfig()
config.setSectionKey("foo","bar","-1")
config.setSectionKey("foo","foo","abc")
config.writeConfig("test.ini")

# test.ini now contains
# [foo]
# bar=-1
# foo=abc

var config2 = loadConfig("test.ini")
let bar = config2.getSectionValue("foo","bar")
let foo = config2.getSectionValue("foo","foo")
assert(bar == "-1")
assert(foo == "abc")
echo "OK"
