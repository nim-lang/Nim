include parsecsv
import strutils, os

block: # Tests for reading the header row
  let content = "\nOne,Two,Three,Four\n1,2,3,4\n10,20,30,40,\n100,200,300,400\n"
  writeFile("temp.csv", content)

  var p: CsvParser
  p.open("temp.csv")
  p.readHeaderRow()
  while p.readRow():
    let zeros = repeat('0', p.currRow-2)
    doAssert p.rowEntry("One") == "1" & zeros
    doAssert p.rowEntry("Two") == "2" & zeros
    doAssert p.rowEntry("Three") == "3" & zeros
    doAssert p.rowEntry("Four") == "4" & zeros
  p.close()

  when not defined(testing):
    var parser: CsvParser
    parser.open("temp.csv")
    parser.readHeaderRow()
    while parser.readRow():
      echo "new row: "
      for col in items(parser.headers):
        echo "##", col, ":", parser.rowEntry(col), "##"
    parser.close()
    removeFile("temp.csv")

  # Tidy up
  removeFile("temp.csv")
