discard """
  output: '''derived class 2
base class
'''
"""

import amethods


type
  TDerivedClass* = object of TBaseClass

proc newDerivedClass: ref TDerivedClass =
  new result

method echoType*(x: ref TDerivedClass) =
  echo "derived class 2"

var b, d: ref TBaseClass

b = newBaseClass()
d = newDerivedClass()

#b.echoType()
#d.echoType()

echoAlias d
echoAlias b

