import tables

var xs: Table[int, Table[int, int]]

doAssertRaises(KeyError): reset xs[0]
