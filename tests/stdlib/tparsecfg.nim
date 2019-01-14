discard """
  output: '''OK'''
"""

#bug #6046
import parsecfg
from os import `/`
import stdtest/specialpaths
let file = testBuildDir/"tparsecfg_test.ini"

var config = newConfig()
config.setSectionKey("foo","bar","-1")
config.setSectionKey("foo","foo","abc")
config.writeConfig(file)

# `file` now contains
# [foo]
# bar=-1
# foo=abc

var config2 = loadConfig(file)
let bar = config2.getSectionValue("foo","bar")
let foo = config2.getSectionValue("foo","foo")
assert(bar == "-1")
assert(foo == "abc")
echo "OK"
