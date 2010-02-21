
template withOpenFile(f: expr, filename: string, mode: TFileMode,
                      actions: stmt): stmt =
  block:
    var f: TFile
    if open(f, filename, mode):
      try:
        actions
      finally:
        close(f)
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

