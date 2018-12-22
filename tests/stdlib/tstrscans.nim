discard """
  output: ""
"""

import strscans

block ParsePasswd:
  proc parsePasswd(content: string): seq[string] =
    result = @[]
    var idx = 0
    while true:
      var entry = ""
      if scanp(content, idx, +(~{'\L', '\0'} -> entry.add($_)), '\L'):
        result.add entry
      else:
        break

  const etc_passwd = """root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/bin/sh
bin:x:2:2:bin:/bin:/bin/sh
sys:x:3:3:sys:/dev:/bin/sh
nobody:x:65534:65534:nobody:/nonexistent:/bin/sh
messagebus:x:103:107::/var/run/dbus:/bin/false
"""

  const parsed_etc_passwd = @[
    "root:x:0:0:root:/root:/bin/bash",
    "daemon:x:1:1:daemon:/usr/sbin:/bin/sh",
    "bin:x:2:2:bin:/bin:/bin/sh",
    "sys:x:3:3:sys:/dev:/bin/sh",
    "nobody:x:65534:65534:nobody:/nonexistent:/bin/sh",
    "messagebus:x:103:107::/var/run/dbus:/bin/false",
    ]
  doAssert etc_passwd.parsePasswd == parsed_etc_passwd

block LastNot:
  var idx : int

  idx = 0
  doAssert scanp("foo", idx,  'f', 'o', ~'a')

  idx = 0
  doAssert scanp("foo", idx,  'f', 'o', ~'o') == false

  idx = 0
  doAssert scanp("foox", idx,  'f', 'o', ~'o') == false

  idx = 0
  doAssert scanp("foox", idx,  'f', 'o', ~'a')

block LastOptional:
  var idx = 0
  doAssert scanp("foo", idx, 'f', 'o', 'o', ?'o')

block Tuple:
  var idx = 0
  doAssert scanp("foo", idx,  ('f', 'o', 'o'))

block NotWithOptional:
  var idx : int

  idx = 0
  doAssert scanp("bc", idx, ~(?'b', 'c')) == false

  idx = 0
  doAssert scanp("c", idx, ~(?'b', 'c')) == false

  idx = 0
  doAssert scanp("b", idx, ~(?'b', 'c'))

block NotEmpty:
  var idx = 0
  doAssert scanp("", idx, ~()) == false

block EmptyTuple:
  var idx = 0
  doAssert scanp("ab", idx, 'a', (), 'b')

block Arrow:
  let text = "foo;bar;baz;"
  var idx = 0
  var res = ""
  doAssert scanp(text, idx, +(~{';','\0'} -> (discard $_)), ';')
  doAssert scanp(text, idx, +(~{';','\0'} -> (discard $_)), ';')
  doAssert scanp(text, idx, +(~{';','\0'} -> (discard $_)), ';')
  doAssert scanp(text, idx, +(~{';','\0'} -> (discard $_)), ';') == false
