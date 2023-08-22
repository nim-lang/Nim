discard """
  output: "bar"
"""

import tables

var tab: Table[string, string]

tab["foo"] = "bar"
echo tab["foo"]

#!EDIT!#

discard """
  output: "bar 3"
"""

import tables

var tab: Table[string, string]
var tab2: Table[string, int]

tab["foo"] = "bar"
tab2["meh"] = 3
echo tab["foo"], " ", tab2["meh"]

#!EDIT!#

discard """
  output: "3"
"""

import tables

var tab2: Table[string, int]

tab2["meh"] = 3
echo tab2["meh"]
