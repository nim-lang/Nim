
import unittest

from algorithm import SortOrder
import tables

suite "tables":
  test "sortedPairs string":
    let t = {
      "x":"", "y":"", "2":"", "_":"", "a": "", "b": "", "c": "",
      "d": "", " ": "", "#": "",
    }.toTable()
    doAssert t.len == 10
    var cnt = 0
    var old_key = ""
    for key, val in sortedPairs(t, system.cmp[string]):
      if old_key != "":
        doAssert old_key < key
      old_key = key
      cnt.inc
    doAssert cnt == 10

  test "sortedPairs string desc":
    let t = {
      "x":"", "y":"", "2":"", "_":"", "a": "", "b": "", "c": "",
      "d": "", " ": "", "#": "",
    }.toTable()
    var cnt = 0
    var old_key = ""
    for key, val in sortedPairs(t, system.cmp[string], SortOrder.Descending):
      if old_key != "":
        doAssert old_key > key
      old_key = key
      cnt.inc
    doAssert cnt == 10

  test "sortedPairs int":
    let t = {
      0: "", 2: "", 4: "", 6: "",
      1: "", 3: "", 5: "", 7: "",
    }.toTable()
    doAssert t.len == 8
    var cnt = 0
    var old_key = -1
    for key, val in sortedPairs(t, system.cmp[int]):
      doAssert old_key < key
      old_key = key
      cnt.inc
    doAssert cnt == 8
