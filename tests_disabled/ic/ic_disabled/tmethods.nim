discard """
  output: '''Base abc'''
"""

import mbaseobj

var c = Base(s: "abc")
m c

#!EDIT!#

discard """
  output: '''Base abc
Inherited abc'''
"""

import mbaseobj

type
  Inherited = ref object of Base

method m(i: Inherited) =
  procCall m(Base i)
  echo "Inherited ", i.s

var c = Inherited(s: "abc")
m c

