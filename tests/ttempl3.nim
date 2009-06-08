
template withOpenFile(f, filename, mode: expr, actions: stmt): stmt =
  block:
    var f: TFile
    if openFile(f, filename, mode):
      try:
        actions
      finally:
        closeFile(f)
    else:
      quit("cannot open for writing: " & filename)
    
withOpenFile(txt, "ttempl3.txt", fmWrite):
  writeln(txt, "line 1")
  txt.writeln("line 2")
  
# Test zero argument template: 
template ha: expr = myVar[0]
  
var
  myVar: array[0..1, int]
  
ha = 1  
echo(ha)

