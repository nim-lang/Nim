discard """
  targets: "c js"
"""

import parsecfg, streams, sequtils

when not defined(js):
  from stdtest/specialpaths import buildDir
  import os
  # bug #6046
  block:
    var config = newConfig()
    config.setSectionKey("foo", "bar", "-1")
    config.setSectionKey("foo", "foo", "abc")

    const file = buildDir / "tparsecfg.ini"
    config.writeConfig(file)

    # file now contains
    # [foo]
    # bar=-1
    # foo=abc

    var config2 = loadConfig(file)
    let bar = config2.getSectionValue("foo", "bar")
    let foo = config2.getSectionValue("foo", "foo")
    doAssert(bar == "-1")
    doAssert(foo == "abc")

## Creating a configuration file.
var dict1 = newConfig()
dict1.setSectionKey("", "charset", "utf-8")
dict1.setSectionKey("Package", "name", "hello")
dict1.setSectionKey("Package", "--threads", "on")
dict1.setSectionKey("Author", "name", "lihf8515")
dict1.setSectionKey("Author", "qq", "10214028")
dict1.setSectionKey("Author", "email", "lihaifeng@wxm.com")
var ss = newStringStream()
dict1.writeConfig(ss)

## Reading a configuration file.
let dict2 = loadConfig(newStringStream(ss.data))
doAssert dict2.getSectionValue("", "charset") == "utf-8"
doAssert dict2.getSectionValue("Package", "--threads") == "on"
doAssert dict2.getSectionValue("Package", "name") == "hello"
doAssert dict2.getSectionValue("Author", "name") == "lihf8515"
doAssert dict2.getSectionValue("Author", "qq") == "10214028"
doAssert dict2.getSectionValue("Author", "email") == "lihaifeng@wxm.com"
doAssert toSeq(dict2.sections) == @["", "Package", "Author"]

## Modifying a configuration file.
var dict3 = loadConfig(newStringStream(ss.data))
dict3.setSectionKey("Author", "name", "lhf")
doAssert $dict3 == """charset=utf-8
[Package]
name=hello
--threads:on
[Author]
name=lhf
qq=10214028
email="lihaifeng@wxm.com"
"""

## Deleting a section key in a configuration file.
var dict4 = loadConfig(newStringStream(ss.data))
dict4.delSectionKey("Author", "email")
doAssert $dict4 == """charset=utf-8
[Package]
name=hello
--threads:on
[Author]
name=lihf8515
qq=10214028
"""

block:
  var dict = loadConfig(newStringStream("""[Simple Values]
  key=value
  spaces in keys=allowed
  spaces in values=allowed as well
  spaces around the delimiter = obviously
  you can also use : to delimit keys from values
  [All Values Are Strings]
  values like this: 19990429
  or this: 3.14159265359
  are they treated as numbers : no
  integers floats and booleans are held as: strings
  can use the API to get converted values directly: true
  [No Values]
  key_without_value
  # empty string value is not allowed =
  [ Seletion A   ]
  space around section name will be ignored
  [You can use comments]
  # like this
  ; or this
  # By default only in an empty line.
  # Inline comments can be harmful because they prevent users
  # from using the delimiting characters as parts of values.
  # That being said, this can be customized.
      [Sections Can Be Indented]
          can_values_be_as_well = True
          does_that_mean_anything_special = False
          purpose = formatting for readability
          # Did I mention we can indent comments, too?
  """)
  )

  let section1 = "Simple Values"
  doAssert dict.getSectionValue(section1, "key") == "value"
  doAssert dict.getSectionValue(section1, "spaces in keys") == "allowed"
  doAssert dict.getSectionValue(section1, "spaces in values") == "allowed as well"
  doAssert dict.getSectionValue(section1, "spaces around the delimiter") == "obviously"
  doAssert dict.getSectionValue(section1, "you can also use") == "to delimit keys from values"

  let section2 = "All Values Are Strings"
  doAssert dict.getSectionValue(section2, "values like this") == "19990429"
  doAssert dict.getSectionValue(section2, "or this") == "3.14159265359"
  doAssert dict.getSectionValue(section2, "are they treated as numbers") == "no"
  doAssert dict.getSectionValue(section2, "integers floats and booleans are held as") == "strings"
  doAssert dict.getSectionValue(section2, "can use the API to get converted values directly") == "true"

  let section3 = "Seletion A"
  doAssert dict.getSectionValue(section3, 
    "space around section name will be ignored", "not an empty value") == ""

  let section4 = "Sections Can Be Indented"
  doAssert dict.getSectionValue(section4, "can_values_be_as_well") == "True"
  doAssert dict.getSectionValue(section4, "does_that_mean_anything_special") == "False"
  doAssert dict.getSectionValue(section4, "purpose") == "formatting for readability"
