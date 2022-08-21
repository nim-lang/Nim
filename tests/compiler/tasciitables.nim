import stdtest/unittest_light
import std/private/asciitables

import strformat

proc alignTableCustom(s: string, delim = '\t', sep = ","): string =
  for cell in parseTableCells(s, delim):
    result.add fmt"({cell.row},{cell.col}): "
    for i in cell.text.len..<cell.width:
      result.add " "
    result.add cell.text
    if cell.col < cell.ncols-1:
      result.add sep
    if cell.col == cell.ncols-1 and cell.row < cell.nrows - 1:
      result.add '\n'

proc testAlignTable() =
  block: # test with variable width columns
    var ret = ""
    ret.add "12\t143\tbcdef\n"
    ret.add "2\t14394852020\tbcdef\n"
    ret.add "45342\t1\tbf\n"
    ret.add "45342\t1\tbsadfasdfasfdasdff\n"
    ret.add "453232323232342\t1\tbsadfasdfasfdasdff\n"
    ret.add "45342\t1\tbf\n"
    ret.add "45342\t1\tb afasf a ff\n"
    ret.add "4\t1\tbf\n"

    assertEquals alignTable(ret),
      """
12              143         bcdef             
2               14394852020 bcdef             
45342           1           bf                
45342           1           bsadfasdfasfdasdff
453232323232342 1           bsadfasdfasfdasdff
45342           1           bf                
45342           1           b afasf a ff      
4               1           bf                
"""

    assertEquals alignTable(ret, fill = '.', sep = ","),
      """
12.............,143........,bcdef.............
2..............,14394852020,bcdef.............
45342..........,1..........,bf................
45342..........,1..........,bsadfasdfasfdasdff
453232323232342,1..........,bsadfasdfasfdasdff
45342..........,1..........,bf................
45342..........,1..........,b afasf a ff......
4..............,1..........,bf................
"""

    assertEquals alignTableCustom(ret, sep = "  "),
      """
(0,0):              12  (0,1):         143  (0,2):              bcdef
(1,0):               2  (1,1): 14394852020  (1,2):              bcdef
(2,0):           45342  (2,1):           1  (2,2):                 bf
(3,0):           45342  (3,1):           1  (3,2): bsadfasdfasfdasdff
(4,0): 453232323232342  (4,1):           1  (4,2): bsadfasdfasfdasdff
(5,0):           45342  (5,1):           1  (5,2):                 bf
(6,0):           45342  (6,1):           1  (6,2):       b afasf a ff
(7,0):               4  (7,1):           1  (7,2):                 bf
"""

  block: # test with 1 column
    var ret = "12\nasdfa\nadf"
    assertEquals alignTable(ret), """
12   
asdfa
adf  """

  block: # test with empty input
    var ret = ""
    assertEquals alignTable(ret), ""

  block: # test with 1 row
    var ret = "abc\tdef"
    assertEquals alignTable(ret), """
abc def"""

  block: # test with 1 row ending in \t
    var ret = "abc\tdef\t"
    assertEquals alignTable(ret), """
abc def """

  block: # test with 1 row starting with \t
    var ret = "\tabc\tdef\t"
    assertEquals alignTable(ret), """
 abc def """


  block: # test with variable number of cols per row
    var ret = """
a1,a2,a3

b1
c1,c2
,d1
"""
    assertEquals alignTableCustom(ret, delim = ',', sep = ","),
      """
(0,0): a1,(0,1): a2,(0,2): a3
(1,0):   ,(1,1):   ,(1,2):   
(2,0): b1,(2,1):   ,(2,2):   
(3,0): c1,(3,1): c2,(3,2):   
(4,0):   ,(4,1): d1,(4,2):   
"""

testAlignTable()
