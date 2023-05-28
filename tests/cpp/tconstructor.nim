discard """
  targets: "cpp"
  cmd: "nim cpp $file"
  output: '''
1
'''
"""

{.emit:"""/*TYPESECTION*/
struct CppClass {
  int x;
  int y;
  CppClass(int inX, int inY) {
    this->x = inX;
    this->y = inY;
  }
  //CppClass() = default;
};
""".}

type  CppClass* {.importcpp, inheritable.} = object
  x: int32
  y: int32

proc makeCppClass(x, y: int32): CppClass {.importcpp: "CppClass(@)", constructor.}
#test globals are init with the constructor call
var shouldCompile {.used.} = makeCppClass(1, 2)

proc newCpp*[T](): ptr T {.importcpp:"new '*0()".}

#creation
type NimClassNoNarent* = object
  x: int32

proc makeNimClassNoParent(x:int32): NimClassNoNarent {. constructor.} =
  this.x = x
  discard

let nimClassNoParent = makeNimClassNoParent(1)
echo nimClassNoParent.x #acess to this just fine. Notice the field will appear last because we are dealing with constructor calls here

var nimClassNoParentDef {.used.}: NimClassNoNarent  #test has a default constructor. 

#inheritance 
type NimClass* = object of CppClass

proc makeNimClass(x:int32): NimClass {. constructor:"NimClass('1 #1) : CppClass(0, #1) ".} =
  this.x = x

#optinially define the default constructor so we get rid of the cpp warn and we can declare the obj (note: default constructor of 'tyObject_NimClass__apRyyO8cfRsZtsldq1rjKA' is implicitly deleted because base class 'CppClass' has no default constructor)
proc makeCppClass(): NimClass {. constructor: "NimClass() : CppClass(0, 0) ".} = 
  this.x = 1

let nimClass = makeNimClass(1)
var nimClassDef {.used.}: NimClass  #since we explictly defined the default constructor we can declare the obj