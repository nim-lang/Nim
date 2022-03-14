import tables
import std/assertions
var xs: Table[int, Table[int, int]]

doAssertRaises(KeyError): reset xs[0]
