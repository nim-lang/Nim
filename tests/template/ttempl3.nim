
template withOpenFile(f: expr, filename: string, mode: TFileMode,
                      actions: stmt): stmt {.immediate.} =
  block:
    # test that 'f' is implicitly 'injecting':
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
  
var
  myVar: array[0..1, int]

# Test zero argument template: 
template ha: expr = myVar[0]
  
ha = 1  
echo(ha)


# Test identifier generation:
template prefix(name: expr): expr {.immediate.} = `"hu" name`

var `hu "XYZ"` = "yay"

echo prefix(XYZ)

template typedef(name: expr, typ: typeDesc) {.immediate, dirty.} =
  type
    `T name`* = typ
    `P name`* = ref `T name`
    
typedef(myint, int)
var x: PMyInt


# Test UFCS

type
  Foo = object
    arg: int

proc initFoo(arg: int): Foo =
  result.arg = arg

template create(typ: typeDesc, arg: expr): expr = `init typ`(arg)

var ff = Foo.create(12)

echo ff.arg
