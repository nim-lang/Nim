discard """
  output: '''@[11, 12, 13]
@[11, 12, 13]
@[1, 3, 5]
@[1, 3, 5]
gppcbs
gppcbs
fpqeew
fpqeew
[11, 12, 13]
[11, 12, 13]
[11, 12, 13]
[11, 12, 13]
11 12 13
[11,12,13]
<Students>
  <Student Name="Aprilfoo" />
  <Student Name="bar" />
</Students>
<chapter>
    <title>This is a Docbook title</title>
    <para>
        This is a Docbook paragraph containing <emphasis>emphasized</emphasis>,
        <literal>literal</literal> and <replaceable>replaceable</replaceable>
        text. Sometimes scrunched together like this:
        <literal>literal</literal><replaceable>replaceable</replaceable>
        and sometimes not:
        <literal>literal</literal> <replaceable>replaceable</replaceable>
    </para>
</chapter>'''
"""

block:
  var xs = @[1,2,3]
  for x in xs.mitems:
    x += 10
  echo xs

block:
  var xs = [1,2,3]
  for x in xs.mitems:
    x += 10
  echo(@xs)

block:
  var xs = @[1,2,3]
  for i, x in xs.mpairs:
    x += i
  echo xs

block:
  var xs = [1,2,3]
  for i, x in xs.mpairs:
    x += i
  echo(@xs)

block:
  var x = "foobar"
  for c in x.mitems:
    inc c
  echo x

block:
  var x = "foobar"
  var y = cast[cstring](addr x[0])
  for c in y.mitems:
    inc c
  echo x

block:
  var x = "foobar"
  for i, c in x.mpairs:
    inc c, i
  echo x

block:
  var x = "foobar"
  var y = cast[cstring](addr x[0])
  for i, c in y.mpairs:
    inc c, i
  echo x

import lists

block:
  var sl = initSinglyLinkedList[int]()
  sl.prepend(3)
  sl.prepend(2)
  sl.prepend(1)
  for x in sl.mitems:
    x += 10
  echo sl

block:
  var sl = initDoublyLinkedList[int]()
  sl.append(1)
  sl.append(2)
  sl.append(3)
  for x in sl.mitems:
    x += 10
  echo sl

block:
  var sl = initDoublyLinkedRing[int]()
  sl.append(1)
  sl.append(2)
  sl.append(3)
  for x in sl.mitems:
    x += 10
  echo sl

import deques

block:
  var q = initDeque[int]()
  q.addLast(1)
  q.addLast(2)
  q.addLast(3)
  for x in q.mitems:
    x += 10
  echo q

import json

block:
  var j = parseJson """{"key1": 1, "key2": 2, "key3": 3}"""
  for key,val in j.pairs:
    val.num += 10
  echo j["key1"], " ", j["key2"], " ", j["key3"]

block:
  var j = parseJson """[1, 2, 3]"""
  for x in j.mitems:
    x.num += 10
  echo j

import xmltree, xmlparser, parsexml, streams, strtabs

block:
  var d = parseXml(newStringStream """<Students>
    <Student Name="April" Gender="F" DateOfBirth="1989-01-02" />
    <Student Name="Bob" Gender="M"  DateOfBirth="1990-03-04" />
  </Students>""")
  for x in d.mitems:
    x = <>Student(Name=x.attrs["Name"] & "foo")
  d[1].attrs["Name"] = "bar"
  echo d

block:
  var d = parseXml(newStringStream """<chapter>
    <title>This is a Docbook title</title>
    <para>
        This is a Docbook paragraph containing <emphasis>emphasized</emphasis>,
        <literal>literal</literal> and <replaceable>replaceable</replaceable>
        text. Sometimes scrunched together like this:
        <literal>literal</literal><replaceable>replaceable</replaceable>
        and sometimes not:
        <literal>literal</literal> <replaceable>replaceable</replaceable>
    </para>
</chapter>""",{reportComments, reportWhitespace})
  echo d
