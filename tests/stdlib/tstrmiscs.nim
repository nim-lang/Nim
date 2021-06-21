import strmisc


doAssert expandTabs("\t", 4) == "    "
doAssert expandTabs("\tfoo\t", 4) == "    foo "
doAssert expandTabs("\tfoo\tbar", 4) == "    foo bar"
doAssert expandTabs("\tfoo\tbar\t", 4) == "    foo bar "
doAssert expandTabs("", 4) == ""
doAssert expandTabs("", 0) == ""
doAssert expandTabs("\t\t\t", 0) == ""

doAssert partition("foo:bar", ":") == ("foo", ":", "bar")
doAssert partition("foobarbar", "bar") == ("foo", "bar", "bar")
doAssert partition("foobarbar", "bank") == ("foobarbar", "", "")
doAssert partition("foobarbar", "foo") == ("", "foo", "barbar")
doAssert partition("foofoobar", "bar") == ("foofoo", "bar", "")

doAssert rpartition("foo:bar", ":") == ("foo", ":", "bar")
doAssert rpartition("foobarbar", "bar") == ("foobar", "bar", "")
doAssert rpartition("foobarbar", "bank") == ("", "", "foobarbar")
doAssert rpartition("foobarbar", "foo") == ("", "foo", "barbar")
doAssert rpartition("foofoobar", "bar") == ("foofoo", "bar", "")
